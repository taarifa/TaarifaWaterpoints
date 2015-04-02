angular.module('taarifaWaterpointsApp')

  .controller 'DashMapCtrl', ($scope, $http, $q, $timeout, modalSpinner, waterpointStats, Waterpoint) ->

    $scope.hoverText = ""
    $scope.choroChoice = "percFun"

    getFeaturedItem = (feature) ->
      res = {}
      props = feature.properties

      if props.hasOwnProperty "District_N"
        res.type = "district"
        res.name = props.District_N
        res.code = +props.District_C
      else if props.hasOwnProperty "Region_Nam"
        res.type = "region"
        res.name = props.Region_Nam
        res.code = +props.Region_Cod
      else
        throw new Error("Unknown geo layer")

      # FIXME: looking up by name which not correct. Should really be by
      # code by this causes issues down the line as the population data
      # does not contain any codes
      res.item = $scope[res.type + "Map"][res.name.toLowerCase()]
      res

    initMap = (waterpoints, mapCenter) ->

      ######################
      ### EVENT HANDLERS ###
      ######################
      mouseOver = (e) ->
        it = getFeaturedItem(e.target.feature)

        if it.item
          hoverText = it.name + ": " + it.item[$scope.choroChoice].toPrecision(3) + "%"
        else
          hoverText = it.name + ": unknown"

        $scope.$apply (scope) ->
          scope.hoverText = hoverText

        layer = e.target
        layer.setStyle
          weight: 2
          color: '#666'
          fillOpacity: 0.8

      onClick = (e) ->
        it = getFeaturedItem(e.target.feature)
        if it.item and it.type == "region"
          $scope.drillDown(it.item[it.type + "_name"], it.type + "_name", true)

      ##############
      ### STYLES ###
      ##############
      colScale = d3.scale.linear()
                    .domain([0,50,100])
                    .range(["red","orange","green"])

      style = (feature) ->
        it = getFeaturedItem(feature)
        color = unless it.item then "gray" else colScale(it.item[$scope.choroChoice])

        s =
          fillColor: color
          weight: 2
          opacity: 1
          color: 'white'
          dashArray: '3'
          fillOpacity: 0.65

      ###############
      ### HELPERS ###
      ###############
      getTopoJsonLayer = (url, featureName) ->
        $http.get(url, cache: true).then (response) ->
          features = topojson.feature(response.data, response.data.objects[featureName]).features
          geojson = L.geoJson(features, {
            style
            onEachFeature: (feature, layer) ->
              layer.on
                mouseover: mouseOver
                mouseout: (e) ->
                  geojson.resetStyle(e.target)
                  $scope.$apply (scope) ->
                    scope.hoverText = ""
                click: onClick
          })
          [features, geojson]

      makeLegend = (map) ->
        legend = L.control(
          position: 'bottomright'
        )

        legend.onAdd = (map) ->
          div = L.DomUtil.create('div', 'legend')

          [0,25,50,75,100].forEach((x) ->
            div.innerHTML += '<i style="background:' + colScale(x) + '"></i> ' + x + "%<br />"
          )

          return div

        legend.addTo(map)

      ##############
      ### LAYERS ###
      ##############
      osmLayer = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        attribution: '(c) OpenStreetMap'
      )

      satLayer = L.tileLayer('http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        attribution: '(c) Esri'
      )

      categoryMap =
        "functional" : 0
        "not functional" : 1
        "needs repair" : 2

      clusterLayer = new PruneClusterForLeaflet()
      clusterLayer.Cluster.Size = 100

      waterpoints.forEach((x) ->
        coords = x.location.coordinates
        m = new PruneCluster.Marker(coords[1], coords[0])
        m.category = categoryMap[x.status_group]
        clusterLayer.RegisterMarker(m))

      ################
      ### OVERLAYS ###
      ################
      $q.all([
        getTopoJsonLayer("data/tz_regions.topojson", "tz_regions")
        getTopoJsonLayer("data/tz_districts.topojson", "tz_districts")
      ]).then((data) ->

        [regions, regionLayer]    = data[0]
        [districts, districtLayer]= data[1]

        ################
        ### MAKE MAP ###
        ################
        baseMaps =
          "Open Street Map": osmLayer
          "Satellite": satLayer

        overlayControls =
          "Regions": regionLayer
          "Districts": districtLayer

        map = L.map('nationalDashMap',
          center: mapCenter
          zoom: 5
          fullscreenControl: true
          layers: [satLayer, regionLayer, clusterLayer]
        )
        makeLegend(map)

        # Add a layer selector
        layerSelector = L.control.layers(baseMaps, overlayControls).addTo(map)

        # Start watching
        $scope.$watch('choroChoice', (val) ->
          return unless val

          layers = [regionLayer, districtLayer]

          layers.forEach (l) ->
            l.setStyle(style)
            if map.hasLayer(l)
              map.removeLayer(l)
              map.addLayer(l)

          regionLayer.setStyle(style)
          districtLayer.setStyle(style)
        )

        $scope.$watch('params.region', (val) ->
          # find the matching geojson feature and refocus the map
          return unless val

          # only 26 regions so a simple linear search is ok
          for f in regions
            it = getFeaturedItem(f)

            if it.name.toLowerCase() == val.name.toLowerCase()
              # Note: only assumes two different nesting levels
              if f.geometry.coordinates[0][0].length == 2
                numToUnpack = 1
              else
                numToUnpack = 2
              points = L.GeoJSON.coordsToLatLngs(f.geometry.coordinates, numToUnpack)
              # instantiate as multipolygon to get the bounds
              bounds = L.multiPolygon(points).getBounds()
              map.fitBounds(bounds)
              return
        )
        # FIXME: find a better solution than this "magic number" for timeout
        $timeout ->
          map.invalidateSize()
        , 2000
        return map
      )

    modalSpinner.open()

    # Get the boundaries and layers
    $q.all([
      # Assumes unique names (which is luckily the case)
      waterpointStats.getStats(null, null, null, "region_name", true)
      waterpointStats.getStats(null, null, null, "district_name", true)
    ]).then((data) ->
      # Add the regions and district to the template scope
      addToScope = (stats, name) ->
        tmp = stats.map((x) -> x[name + "_name"].name.toLowerCase())
        $scope[name + "Map"] = _.object(tmp, stats)

      # data contains stats for region and district
      addToScope(data[0], "region")
      addToScope(data[1], "district")

      # Initialise the map
      initMap([], new L.LatLng(-6.3153, 35.15625))
      modalSpinner.close()
    )
