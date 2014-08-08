angular.module('taarifaWaterpointsApp')

  .controller 'DashMapCtrl', ($scope, $http, leafletData, $timeout, waterpointStats) ->

    $scope.hoverText = ""
    $scope.choroChoice = "percFun"

    getRegItem = (feature) ->
      regname = feature.properties.REGNAME.toLowerCase()
      regitem = $scope.regionMap[regname]

    initMap = (regions, waterpoints) ->

      osmLayer = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        attribution: '(c) OpenStreetMap'
      )

      satLayer = L.tileLayer('http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        attribution: '(c) Esri'
      )

      regionMouseOver = (e) ->
        r = getRegItem(e.target.feature)

        if r
          hoverText = r.region + ": " + r[$scope.choroChoice].toPrecision(3) + " %"
        else
          hoverText = ""

        $scope.$apply(
            $scope.hoverText = hoverText
        )

        layer = e.target
        layer.setStyle
          weight: 2
          color: '#666'
          fillOpacity: 0.8

        if !L.Browser.ie && !L.Browser.opera
          layer.bringToFront()

      regionMouseOut = (e) ->
        regLayer.resetStyle(e.target)
        $scope.$apply(
            $scope.hoverText = ""
        )

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
        regitem = getRegItem(feature)

        if not regitem
          console.log("Warning: no region match for " + feature.properties.REGNAME)
          color = "gray"
        else
          color = colScale(regitem[$scope.choroChoice])

        s =
          fillColor: color
          weight: 2
          opacity: 1
          color: 'white'
          dashArray: '3'
          fillOpacity: 0.65

      onEachFeature = (feature, layer) ->
        layer.on(
          mouseover: regionMouseOver,
          mouseout: regionMouseOut,
          click: regionClick
        )

      regLayer = L.geoJson(regions,
        style: style
        onEachFeature: onEachFeature
      )

      map = L.map('nationalDashMap',
        center: new L.LatLng(-6.3153, 35.15625),
        zoom: 5,
        layers: [osmLayer, satLayer, regLayer]
      )

      baseMaps =
        "Open Street Map": osmLayer
        "Satellite": satLayer

      overlayMaps =
        "Regions": regLayer

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

        map.removeLayer(regLayer)
        regLayer.setStyle(style)
        map.addLayer(regLayer)
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


    # get the region boundaries
    $http.get("data/tz_regions.geojson", cache: true)
      .success((regions, status) ->
        # get the wateropint data per region
        waterpointStats.getStats(null, null, null, "region", true, (waterpoints) ->

          # create an associative map by region name
          regs = _.pluck(waterpoints, "region").map((x) -> x.toLowerCase())
          regionMap = _.object(regs, waterpoints)

          $scope.regionMap = regionMap

          initMap(regions, waterpoints)
        ))
