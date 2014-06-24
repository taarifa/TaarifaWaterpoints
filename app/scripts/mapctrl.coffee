angular.module('taarifaWaterpointsApp')

  .controller 'DashMapCtrl', ($scope, $http) ->
    cartoUrl = 'http://worldbank.cartodb.com/api/v2/viz/9af2a2ec-e414-11e3-94c5-0edbca4b5057/viz.json'
    map = null

    carto = cartodb.createVis 'map_canvas', cartoUrl,
      center_lat: -5.5691
      center_lon: 34.9090
      zoom: 5

    carto
      .done (vis,layers) ->
        # layer 0 is the base layer, layer 1 is cartodb layer
        # setInteraction is disabled by default
        layers[1].setInteraction true

        # you can get the native map to work with it
        # depending if you use google maps or leaflet
        map = vis.getNativeMap()
      .error (err) ->
        console.log err
    return
