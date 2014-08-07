angular.module('taarifaWaterpointsApp')

  .controller 'DashMapCtrl', ($scope, $http, leafletData, $timeout, waterpointStats) ->

    $scope.regionMap = null
    $scope.geojson = null
    $scope.hoverText = null

    mapObj = null

    # keep a copy of the native map
    leafletData.getMap("nationalDashMap").then( (map) -> mapObj = map )

    $scope.center =
      lat: -7.984246
      lng: 34.672852
      zoom: 5

    $scope.layers =
      baselayers:
        osm:
          name: 'OSM'
          url: 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
          type: 'xyz'
        sat:
          name: 'Satellite'
          url: 'http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
          type: 'xyz'
          attribution: 'Tiles (c) Esri'

    $scope.$on("leafletDirectiveMap.geojsonMouseover", (ev, leafletEvent) ->
      layer = leafletEvent.target
      layer.setStyle
        weight: 2
        color: '#666'
        fillOpacity: 1
      layer.bringToFront())

    $scope.$on("leafletDirectiveMap.geojsonClick", (ev, featureSelected, leafletEvent) ->
      mapObj.fitBounds(leafletEvent.target.getBounds()))

    getRegItem = (feature) ->
      regname = feature.properties.REGNAME.toLowerCase()
      regitem = $scope.regionMap[regname]

    $scope.$watch("geojson.selected", (d) ->
      if d
        r = getRegItem(d)
        if r
          $scope.hoverText = r.region + ": " + r.percFun.toPrecision(3) + " %"
        else
          $scope.hoverText = ""
      else
        $scope.hoverText = ""
    )

    # get the region boundaries
    $http.get("data/tz_regions.geojson", cache: true)
      .success((regions, status) ->
        # get the wateropint data per region
        waterpointStats.getStats(null, null, null, "region", true, (waterpoints) ->

          # create an associative map by region name
          regs = _.pluck(waterpoints, "region").map((x) -> x.toLowerCase())
          regionMap = _.object(regs, waterpoints)

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
              color = colScale(regitem.percFun)

            s =
              fillColor: color
              weight: 2
              opacity: 1
              color: 'white'
              dashArray: '3'
              fillOpacity: 0.65

          $scope.regionMap = regionMap

          $scope.geojson =
            data: regions
            style: style
            resetStyleOnMouseout: true
        ))

    redrawMap = () ->
      leafletData.getMap("nationalDashMap").then((map) -> map.invalidateSize())

    # FIXME: for some reason this does not work
    #$scope.$on('gridster-resized',(newSizes) ->
    #  redrawMap()
    #)

    $timeout(redrawMap, 1000)
