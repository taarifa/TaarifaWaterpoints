angular.module('taarifaWaterpointsApp')

  .controller 'DashMapCtrl', ($scope, $http, $q, $timeout, modalSpinner, waterpointStats, Waterpoint) ->

    $scope.hoverText = ""
    $scope.choroChoice = "percFun"

    # FIXME: "ward" and "region" should be defined elsewhere I think
    # NOTE: Rewritten to avoid too much "ward" / "region" lookup
    getFeatureType = (feature) ->
      return if feature.properties.hasOwnProperty "REGNAME" then "region" else "ward"

    getFeaturedItem = (feature) ->
      itemType = getFeatureType(feature)
      nameProperty = if itemType == "region" then "REGNAME" else "Ward_Name"
      name = feature.properties[nameProperty].toLowerCase()
      item = $scope[itemType + "Map"][name]
      [name, item, itemType]

    getItem = (feature) ->
      featureType = getFeatureType(feature)
      return [featureType, getFeaturedItem(feature)[1]]


    initMap = (waterpoints, mapCenter) ->

      ######################
      ### EVENT HANDLERS ###
      ######################
      mouseOver = (e) ->
        [name, item, itemType] = getFeaturedItem(e.target.feature)

        if item
          hoverText = item[itemType] + ": " + item[$scope.choroChoice].toPrecision(3) + "%"
        else
          hoverText = name + ": unknown"

        $scope.$apply (scope) ->
          scope.hoverText = hoverText

        layer = e.target
        layer.setStyle
          weight: 2
          color: '#666'
          fillOpacity: 0.8

      onClick = (e) ->
        [name, item, itemType] = getFeaturedItem(e.target.feature)
        if item
          $scope.drillDown(item.region, itemType, true)

      ##############
      ### STYLES ###
      ##############
      colScale = d3.scale.linear()
                    .domain([0,50,100])
                    .range(["red","orange","green"])

      style = (feature) ->
        [type, item] = getItem(feature)
        color = unless item then "gray" else colScale(item[$scope.choroChoice])

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
      getTopoJsonLayer = (url, featureName, doClick) ->
        $http.get(url).then (response) ->
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
                click: onClick if doClick
          })

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
        getTopoJsonLayer("data/tz_regions.topojson", "tz_regions", true)
        getTopoJsonLayer("data/tz_wards.topojson", "tz_wards", false)
      ]).then((data) ->

        regionLayer = data[0]
        wardLayer   = data[1]

        ################
        ### MAKE MAP ###
        ################
        baseMaps =
          "Open Street Map": osmLayer
          "Satellite": satLayer

        overlayControls =
          "Regions": regionLayer
          "Wards": wardLayer

        map = L.map('nationalDashMap',
          center: mapCenter
          zoom: 5
          fullscreenControl: true
          layers: [satLayer, regionLayer, wardLayer, clusterLayer]
        )
        makeLegend(map)

        # Add a layer selector
        layerSelector = L.control.layers(baseMaps, overlayControls).addTo(map)

        # Start watching
        $scope.$watch('choroChoice', (val) ->
          return unless val

          regionLayer.setStyle(style)
          wardLayer.setStyle(style)

          if map.hasLayer(regionLayer)
            map.removeLayer(regionLayer)
            map.addLayer(regionLayer)

          if map.hasLayer(wardLayer)
            map.removeLayer(wardLayer)
            map.addLayer(wardLayer)
        )

        $scope.$watch('params.region', (val) ->
          # find the matching geojson feature and refocus the map
          return unless val

          # only 26 regions so a simple linear search is ok
          for f in regions.features
            r = f.properties.REGNAME.toLowerCase()

            if r == val.toLowerCase()
              # turn into lat lon arrays
              points = L.GeoJSON.coordsToLatLngs(f.geometry.coordinates,2)
              # instantiate as multipolygon to get the bounds
              bounds = L.multiPolygon(points).getBounds()
              map.fitBounds(bounds)
              return
        )
      )

    modalSpinner.open()

    # Get the boundaries and layers
    $q.all([
      waterpointStats.getStats(null, null, null, "region", true)
      # FIXME: relies on the fact that wards are uniquely named
      waterpointStats.getStats(null, null, null, "ward", true)
    ]).then((data) ->
      # Add the regions and wards to the template scope
      addToScope = (stats, name) ->
        tmp = _.pluck(stats, name).map((x) -> x.toLowerCase())
        $scope[name + "Map"] = _.object(tmp, stats)

      # data contains stats for region and ward
      addToScope(data[0], "region")
      addToScope(data[1], "ward")

      # Initialise the map
      map = initMap([], new L.LatLng(-6.3153, 35.15625))
      modalSpinner.close()
    )
