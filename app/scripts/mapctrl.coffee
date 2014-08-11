angular.module('taarifaWaterpointsApp')

  .controller 'DashMapCtrl', ($scope, $http, $q, leafletData, $timeout, modalSpinner, waterpointStats, Waterpoint) ->

    $scope.hoverText = ""
    $scope.choroChoice = "percFun"

    getFeatureType = (feature) ->
      if feature.properties.hasOwnProperty("REGNAME")
        return "region"
      else
        return "ward"

    getWardItem = (feature) ->
      wardname = feature.properties.Ward_Name.toLowerCase()
      regitem = $scope.wardMap[wardname]

    getRegItem = (feature) ->
      regname = feature.properties.REGNAME.toLowerCase()
      regitem = $scope.regionMap[regname]

    getItem = (feature) ->
      if getFeatureType(feature) == "region"
        return ["region", getRegItem(feature)]
      else
        return ["ward", getWardItem(feature)]

    initMap = (regions, wards, waterpoints) ->

      osmLayer = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        attribution: '(c) OpenStreetMap'
      )

      satLayer = L.tileLayer('http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        attribution: '(c) Esri'
      )

      mouseOver = (e) ->
        [type,item] = getItem(e.target.feature)

        if item
          hoverText = item[type] + ": " + item[$scope.choroChoice].toPrecision(3) + "%"
        else
          hoverText = ""

        $scope.$apply (scope) ->
          scope.hoverText = hoverText

        layer = e.target
        layer.setStyle
          weight: 2
          color: '#666'
          fillOpacity: 0.8

        #if !L.Browser.ie && !L.Browser.opera
        #  layer.bringToFront()

      wardMouseOut = (e) ->
        wardLayer.resetStyle(e.target)
        $scope.$apply (scope) ->
          scope.hoverText = ""

      regionMouseOut = (e) ->
        regLayer.resetStyle(e.target)
        $scope.$apply (scope) ->
          scope.hoverText = ""

      regionClick = (e) ->
        # dont do this here, the watch below will take care of that
        #map.fitBounds(e.target.getBounds())

        regit = getRegItem(e.target.feature)
        if regit
          $scope.drillDown(regit.region, 'region', true)

      colScale = d3.scale.linear()
                    .domain([0,50,100])
                    .range(["red","orange","green"])

      # how to style the regions
      style = (feature) ->
        [type, item] = getItem(feature)

        if not item
          color = "gray"
        else
          color = colScale(item[$scope.choroChoice])

        s =
          fillColor: color
          weight: 2
          opacity: 1
          color: 'white'
          dashArray: '3'
          fillOpacity: 0.65

      onEachRegionFeature = (feature, layer) ->
        layer.on
          mouseover: mouseOver
          mouseout: regionMouseOut
          click: regionClick

      onEachWardFeature = (feature, layer) ->
        layer.on
          mouseover: mouseOver
          mouseout: wardMouseOut

      regLayer = L.geoJson(regions,
        style: style
        onEachFeature: onEachRegionFeature
      )

      wardLayer = L.geoJson(wards,
        style: style
        onEachFeature: onEachWardFeature
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

      map = L.map('nationalDashMap',
        center: new L.LatLng(-6.3153, 35.15625),
        zoom: 5,
        layers: [satLayer, regLayer, clusterLayer]
      )

      baseMaps =
        "Open Street Map": osmLayer
        "Satellite": satLayer

      overlayMaps =
        "Regions": regLayer
        "Wards": wardLayer
        #"Waterpoints": clusterLayer

      # add a layer selector
      layerSelector = L.control.layers(baseMaps, overlayMaps).addTo(map)

      # add a legend
      legend = L.control(
        position: 'bottomright'
      )

      legend.onAdd = (map) ->
        div = L.DomUtil.create('div', 'legend');

        [0,25,50,75,100].forEach((x) ->
          div.innerHTML += '<i style="background:' + colScale(x) + '"></i> ' + x + "%<br />";
        )

        return div;

      legend.addTo(map);

      $scope.$watch('choroChoice', (val) ->
        if !val then return

        regLayer.setStyle(style)
        wardLayer.setStyle(style)

        if map.hasLayer(regLayer)
          map.removeLayer(regLayer)
          map.addLayer(regLayer)

        if map.hasLayer(wardLayer)
          map.removeLayer(wardLayer)
          map.addLayer(wardLayer)
      )

      $scope.$watch('params.region', (val) ->
        # find the matching geojson feature and refocus the map

        if !val then return

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


    modalSpinner.open()

    # get the boundaries
    $q.all([
      $http.get("data/tz_regions.geojson", cache: true)
      $http.get("data/tz_wards.geojson", cache: true)
      waterpointStats.getStats(null, null, null, "region", true)
      # FIXME: relies on the fact that wards are uniquely named
      waterpointStats.getStats(null, null, null, "ward", true)
    ]).then((results) ->
      regions = results[0].data
      wards = results[1].data
      regionStats = results[2]
      wardStats = results[3]

      # create an associative map by region/ward name
      regs = _.pluck(regionStats, "region").map((x) -> x.toLowerCase())
      regionMap = _.object(regs, regionStats)
      $scope.regionMap = regionMap

      ws = _.pluck(wardStats, "ward").map((x) -> x.toLowerCase())
      wardMap = _.object(ws, wardStats)
      $scope.wardMap = wardMap

      initMap(regions, wards, [])

      modalSpinner.close()
    )
