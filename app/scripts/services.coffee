'use strict'

angular.module('taarifaWaterpointsApp')

  .factory 'ApiResource', ($resource) ->
    (resource, args) ->
      $resource "/api/#{resource}/:id"
      , # Default arguments
        args
      , # Override methods
        query:
          method: 'GET'
          isArray: false
        update:
          method: 'PUT'

  .factory 'Waterpoint', (ApiResource) ->
    ApiResource 'waterpoints'

  .factory 'Facility', (ApiResource) ->
    ApiResource 'facilities'

  .factory 'Request', (ApiResource) ->
    ApiResource 'requests'

  .factory 'Service', (ApiResource) ->
    ApiResource 'services'

  .factory 'Map', (Waterpoint) ->
    # Initially center on Dar es Salaam
    @center =
      lat: -6.7701973
      lng: 39.2664484
      zoom: 6
    @markers = {}
    addMarkers = (waterpoints) =>
      for p in waterpoints._items
        @markers[p._id] =
          # FIXME temporarily disable clustering since it is not properly
          # reinitialized when the MapCtrl controller reloads
          # group: p.district
          lat: p.latitude
          lng: p.longitude
          message: "#{p.wpt_code}<br />" +
            "Status: #{p.status}<br />" +
            "<a href=\"#/waterpoints/edit/#{p._id}\">edit</a><br />" +
            "<a href=\"#/requests/new?waterpoint_id=#{p.wpt_code}\">submit request</a>"
      # This would keep loading further waterpoints as long as there are any.
      # Disabled for performance reasons
      # if waterpoints._links.next
      #   $http.get(waterpoints._links.next.href)
      #     .success addMarkers
    Waterpoint.query
      max_results: 100
      projection:
        _id: 1
        district: 1
        latitude: 1
        longitude: 1
        wpt_code: 1
        status: 1
    , addMarkers
    return this

  # Get an angular-dynamic-forms compatible form description from a Facility
  # given a facility code
  .factory 'FacilityForm', (Facility) ->
    (facility_code) ->
      Facility.get(facility_code: facility_code)
        # Return a promise since dynamic-forms needs the form template in
        # scope when the controller is invoked
        .$promise.then (facility) ->
          fields = facility._items[0].fields
          for f of fields
            # Use the field name as label if no label was specified
            if not fields[f].label?
              fields[f].label = f
            fields[f].type = 'text' if fields[f].type == 'string'
            # FIXME a number field assumes integers, therefore use text
            fields[f].type = 'text' if fields[f].type == 'float'
            fields[f].type = 'number' if fields[f].type == 'integer'
            if fields[f].allowed?
              fields[f].type = 'select'
              options = {}
              options[label] = label: label for label in fields[f].allowed
              fields[f].options = options
            fields[f].class = "form-control"
            fields[f].wrapper = '<div class="form-group"></div>'
          fields.submit =
            type: "submit"
            label: "Save"
            class: "btn btn-primary"
          return fields

  # Get an angular-dynamic-forms compatible form description from a Service
  # given a service code
  .factory 'RequestForm', (Service) ->
    (service_code, params) ->
      Service.get(service_code: service_code)
        # Return a promise since dynamic-forms needs the form template in
        # scope when the controller is invoked
        .$promise.then (service) ->
          dtype2type =
            string: 'text'
            text: 'textarea'
            singlevaluelist: 'select'
            multivaluelist: 'select'
          fields = {}
          for a in service._items[0].attributes when a.variable
            fields[a.code] =
              type: dtype2type[a.datatype] or a.datatype
              required: a.required
              label: a.description
              class: "form-control"
              wrapper: '<div class="form-group"></div>'
              val: params[a.code]
            if a.datatype in ['singlevaluelist', 'multivaluelist']
              fields[a.code].multiple = a.datatype == 'multivaluelist'
              options = {}
              for v in a.values
                options[v.key] =
                  label: v.name
              fields[a.code].options = options
          fields.submit =
            type: "submit"
            label: "Save"
            class: "btn btn-primary"
          return fields
