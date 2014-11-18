'use strict'

angular.module('taarifaWaterpointsApp')

  .factory 'waterpointStats', ($http, $q, populationData) ->
    result = {}

    getStats = (region, district, ward, groupfield, cache) ->
      def = $q.defer()
      url = "/api/waterpoints/stats_by/" + groupfield
      filterFields = {"region_name":region, "district_name":district, "ward_name":ward}
      filters = []

      _.keys(filterFields).forEach((x) ->
        if filterFields[x] then filters.push(x + "=" + filterFields[x]))

      filter = filters.join("&")

      if filter then url += "?" + filter

      # FIXME: use $cacheFactory to cache also the processed data
      $http.get(url, cache: cache)
        .success (data, status, headers, config) ->
          populationData.then( (popData) ->
            geoField = _.contains(['region_name','district_name','ward_name'], groupfield)

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
                  if groupfield == "region_name" then x[groupfield] else null,
                  if groupfield == "district_name" then x[groupfield] else null,
                  if groupfield == "ward_name" then x[groupfield] else null
                )
                if pop > 0
                  x.popReach = f.population / pop * 100
            )

            # sort by % functional waterpoints
            data.sort (a, b) ->
              if a.percFun == b.percFun
                b.count - a.count
              else
                b.percFun - a.percFun

            # all done, call the callback
            def.resolve(data)
          )

      return def.promise

    result.getStats = getStats

    return result

  .factory 'modalSpinner', ($modal, $timeout, $q) ->
    modalInstance = null

    # shared counter to allow multiple invocations of
    # open/close
    ctr = {val: 0}

    return {
      open: (msg, status) ->
        ++ctr.val
        if ctr.val > 1 then return
        modalInstance = $modal.open
          controller: 'ModalSpinnerCtrl'
          templateUrl: '/views/spinnerdlg.html'
          backdrop: 'static'
          size: 'sm'
          resolve:
            msg: ->
              #FIXME this default shouldn't really be here but it's to prevent
              # regression bugs until it's sorted
              return msg or 'Loading waterpoint data.'
            status: ->
              return status or 'Loading data...'

      close: ->
        --ctr.val
        if ctr.val < 1
          modalInstance.opened.then ->
            modalInstance.close()
          ctr.val = 0
    }

  # FIXME: this is fundamentally flawed as lookups by name
  # cause collision problems. Really need new data that includes
  # codes.
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

  .factory 'Map', ($filter) ->
    (id, opts) =>

      defaults =
        clustering: false
        markerType: "regular"
        coverage: false
        heatmap: false
        showScale: false

      options = _.extend(defaults, opts)

      osmLayer = L.tileLayer(
        'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        attribution: '(c) OpenStreetMap')

      satLayer = L.tileLayer(
        'http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        attribution: '(c) Esri')

      baseMaps =
        "Open Street Map": osmLayer
        "Satellite": satLayer

      overlays = {}

      # FIXME: hardcoded categories
      categoryMap =
        "functional" : 0
        "not functional" : 1
        "needs repair" : 2

      if options.clustering
        markerLayer = new PruneClusterForLeaflet()
        markerLayer.Cluster.Size = 100
        markerLayer.PrepareLeafletMarker = (leafletMarker, data) ->
          if leafletMarker.getPopup()
            leafletMarker.setPopupContent data
          else
            leafletMarker.bindPopup data
      else
        markerLayer = L.featureGroup()

      overlays.Waterpoints = markerLayer
      defaultLayers = [osmLayer, markerLayer]

      if options.coverage
        coverageLayer = L.TileLayer.maskCanvas
          radius: 1000
          useAbsoluteRadius: true   # true: r in meters, false: r in pixels
          color: '#000'             # the color of the layer
          opacity: 0.5              # opacity of the not covered area
          noMask: false             # true results in normal (filled) circled, instead masked circles
          lineColor: '#A00'         # color of the circle outline if noMask is true

        overlays["Coverage (1km)"] = coverageLayer

      if options.heatmap
        heatmapLayer = new HeatmapOverlay
          radius: 15
          maxOpacity: .7
          scaleRadius: false
          useLocalExtrema: true

        overlays["Functionality Heatmap"] = heatmapLayer

        # we add the heatmap layer by default
        defaultLayers.push(heatmapLayer)

      map = L.map id,
        center: new L.LatLng -6.3153, 35.15625
        zoom: 5
        fullscreenControl: true
        layers: defaultLayers

      if options.heatmap
        # FIXME: remove the heatmap layer again to workaround
        # https://github.com/pa7/heatmap.js/issues/130
        map.removeLayer(heatmapLayer)

      # add a layer selector
      layerSelector = L.control.layers(baseMaps, overlays).addTo(map)

      # add a distance scale
      if options.showScale
        scale = L.control.scale().addTo(map)

      makePopup = (wp) ->
        cleanKey = (k) ->
          $filter('titlecase')(k.replace("_"," "))

        cleanValue = (k,v) ->
          if v instanceof Date
            v.getFullYear()
          else if k == "location"
            v.coordinates.toString()
          else
            v

        header = '<h5>' + wp.wptcode + ' (<a href="#/waterpoints/edit/' + wp._id + '">Edit</a>)</h5>' +
                 '<span class="popup-key">Status</span>: ' + wp.status_group + '<br />' +
                 '<a href="#/requests/?waterpoint_id=' + wp.wptcode + '">Show reports</a> | ' +
                 '<a href="#/requests/new?waterpoint_id=' + wp.wptcode + '">Submit report</a>' +
                 '<hr style="margin-top:10px; margin-bottom: 10px;" />'

        # FIXME: can't this be offloaded to angular somehow?
        fields = _.keys(wp).sort().map((k) ->
            #cleanKey(k) + String(cleanValue(k, wp[k]))
            '<span class="popup-key">' + cleanKey(k) + '</span>: ' +
            '<span class="popup-value">' + String(cleanValue(k,wp[k])) + '</span>'
          ).join('<br />')

        html = '<div class="popup">' + header + fields + '</div>'

      @clearMarkers = () ->
        if options.clustering
          markerLayer.RemoveMarkers()
        else
          markerLayer.clearLayers()

      # FIXME: more hardcoded statusses
      makeAwesomeIcon = (status) ->
        if status == 'functional'
          color = 'blue'
        else if status == 'not functional'
          color = 'red'
        else if status == 'needs repair'
          color = 'orange'
        else
          color = 'black'

        icon = L.AwesomeMarkers.icon
          prefix: 'glyphicon',
          icon: 'tint',
          markerColor: color

      makeMarker = (wp) ->
        [lng,lat] = wp.location.coordinates
        mt = options.markerType

        if mt == "circle"
          m = L.circleMarker L.latLng(lat,lng),
            stroke: false
            radius: 5
            fillOpacity: 1
            fillColor: statusColor(wp.status_group)
        else
          m = L.marker L.latLng(lat,lng),
              icon: makeAwesomeIcon(wp.status_group)

      @addWaterpoints = (wps) ->
        wps.forEach (wp) ->
          [lng,lat] = wp.location.coordinates

          if options.clustering
            m = new PruneCluster.Marker lat, lng, popup
            m.category = categoryMap[wp.status_group]
            markerLayer.RegisterMarker m
          else
            m = makeMarker(wp)
            popup = makePopup(wp)
            m.bindPopup popup
            markerLayer.addLayer(m)

        if options.coverage
          coords = wps.map (x) -> [x.location.coordinates[1], x.location.coordinates[0]]
          coverageLayer.setData coords

        if options.heatmap
          costMap =
            functional: 0
            "needs repair": 1
            "not functional": 2

          coords = []
          wps.forEach (x) ->
            if x.status_group != "functional"
              coords.push
                lat: x.location.coordinates[1]
                lng: x.location.coordinates[0]
                value: costMap[x.status_group]

          heatmapLayer.setData 
            data: coords


      @zoomToMarkers = () ->
        if options.clustering
          markerLayer.FitBounds()
        else
          bounds = markerLayer.getBounds()
          if bounds.isValid()
            map.fitBounds(bounds)

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
