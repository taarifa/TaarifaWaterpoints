'use strict'

angular.module('taarifaWaterpointsApp')

  .factory 'waterpointStats', ($http, $q, populationData) ->
    result = {}

    getStats = (region, lga, ward, groupfield, cache) ->
      def = $q.defer()
      url = "/api/waterpoints/stats_by/" + groupfield
      filterFields = {"region":region, "lga":lga, "ward":ward}
      filters = []

      _.keys(filterFields).forEach((x) ->
        if filterFields[x] then filters.push(x + "=" + filterFields[x]))

      filter = filters.join("&")

      if filter then url += "?" + filter

      # FIXME: use $cacheFactory to cache also the processed data
      $http.get(url, cache: cache)
        .success (data, status, headers, config) ->
          populationData.then( (popData) ->
            geoField = _.contains(['region','lga','ward'], groupfield)

            data.forEach((x) ->
              f = _.find(x.waterpoints, isFunctional)

              # ensure there is always a functional entry
              if !f
                f = {
                  status: "functional",
                  population: 0,
                  count: 0
                }
                x.waterpoints.push(f)

              x.percFun = f.count / x.count * 100

              x.popReach = 0

              if geoField
                pop = popData.lookup(
                  if groupfield == "region" then x[groupfield] else null,
                  if groupfield == "lga" then x[groupfield] else null,
                  if groupfield == "ward" then x[groupfield] else null
                )
                if pop > 0
                  x.popReach = f.population / pop * 100
            )

            # sort by % functional waterpoints
            data = _.sortBy(data, (x) -> -x.percFun)

            # all done, call the callback
            def.resolve(data)
          )

      return def.promise

    result.getStats = getStats

    return result

  .factory 'modalSpinner', ($modal, $timeout) ->
    modalDlg = null

    # shared counter to allow multiple invocations of
    # open/close
    ctr = {val: 0}

    openSpinner = () ->
      ++ctr.val
      if ctr.val > 1 then return
      modalDlg = $modal.open
        templateUrl: '/views/spinnerdlg.html'
        backdrop: "static"
        size: "sm"

    closeSpinner = () ->
      --ctr.val
      if ctr.val < 1
        # If the close event comes really quickly after the
        # open event the close will fail if the open is not
        # yet completed. Hence add a timeout.
        # FIXME: better solution?
        $timeout(modalDlg.close, 300)
        ctr.val = 0

    res =
        open: openSpinner
        close: closeSpinner

  .factory 'populationData', ($http, $q) ->
    def = $q.defer()
    url = '/data/population_novillages.json'
    result = {}

    $http.get(url).then((data) ->
      #allGrouped = _.groupBy(data.data,"Region")
      #_.keys(grouped).forEach((r) ->
      #  grouped[r] = _.groupBy(grouped[r],"District")
      #  _.keys(grouped[r]).forEach((d) ->
      #    grouped[r][d] = _.groupBy(grouped[r][d],"Ward")))

      # create 3 indices on the data for convenience
      # we can do this since all names happen to be unique
      # FIXME: eventually should be delegated to a database
      regionGroups = _.groupBy(data.data, "Region")
      districtGroups = _.groupBy(data.data, "District")
      wardGroups = _.groupBy(data.data, "Ward")

      lookup = (r,d,w) ->
        try
          if w
            wardGroups[w][0].Both_Sexes
          else if d
            districtGroups[d].filter((d) ->
              d.Ward == "")[0].Both_Sexes
          else if r
            regionGroups[r].filter((d) ->
              !d.District)[0].Both_Sexes
          else
            d3.sum(_.chain(regionGroups)
              .values(regionGroups)
              .flatten()
              .filter((d) ->
                !d.District)
              .pluck("Both_Sexes")
              .value())
        catch e
          console.log("Warning: Failed to lookup population for " +
            r + ", " + d + ", " + w)
          return -1

      result.lookup = lookup

      def.resolve(result))

    return def.promise

  .factory 'ApiResource', ($resource, $http, flash) ->
    (resource, args) ->
      Resource = $resource "/api/#{resource}/:id"
      , # Default arguments
        args
      , # Override methods
        query:
          method: 'GET'
          isArray: false
      Resource.update = (id, data) ->
        # We need to remove special attributes starting with _ since they are
        # not defined in the schema and the data will not validate and the
        # update be rejected
        putdata = {}
        for k, v of data when k[0] != '_'
          putdata[k] = v
        $http.put("/api/#{resource}/"+id, putdata,
                  headers: {'If-Match': data._etag})
        .success (res, status) ->
          if status == 200 and res._status == 'OK'
            flash.success = "#{resource} successfully updated!"
            data._etag = res._etag
          if status == 200 and res._status == 'ERR'
            for field, message of res._issues
              flash.error = "#{field}: #{message}"
      Resource.patch = (id, data, etag) ->
        $http
          method: 'PATCH'
          url: "/api/#{resource}/"+id
          data: data
          headers: {'If-Match': etag}
      return Resource

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
          lat: p.location.coordinates[1]
          lng: p.location.coordinates[0]
          message: "#{p.wpt_code}<br />" +
            "Status: #{p.status_group}<br />" +
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
        location: 1
        wpt_code: 1
        status_group: 1
      strip: 1
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
          typemap =
            string: 'text'
            integer: 'number'
            # FIXME a number field assumes integers, therefore use text
            float: 'number'
            boolean: 'checkbox'
          mkfield = (type, label, step) ->
            type: type
            label: label
            step: step
            class: "form-control"
            wrapper: '<div class="form-group"></div>'
          fields = {}
          for f, v of facility._items[0].fields
            if v.type == 'point'
              fields.longitude = mkfield 'number', 'longitude', 'any'
              fields.latitude = mkfield 'number', 'latitude', 'any'
              fields.longitude.model = 'location.coordinates[0]'
              fields.latitude.model = 'location.coordinates[1]'
            else
              # Use the field name as label if no label was specified
              fields[f] = mkfield typemap[v.type] || v.type, v.label || f
              if v.type in ['float', 'number']
                fields[f].step = 'any'
              if v.allowed?
                fields[f].type = 'select'
                options = {}
                options[label] = label: label for label in v.allowed
                fields[f].options = options
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
