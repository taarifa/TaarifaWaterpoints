'use strict'

angular.module('taarifaWaterpointsApp')
  .controller 'MainCtrl', ($scope, Waterpoint) ->
    Waterpoint.query (waterpoints) ->
      $scope.waterpoints = waterpoints._items
  .controller 'MapCtrl', ($scope, Waterpoint) ->
    $scope.dar =
      lat: -6.7701973
      lng: 39.2664484
      zoom: 6
    $scope.markers = {}
    Waterpoint.query (waterpoints) ->
      for p in waterpoints._items
        $scope.markers[p._id] =
          group: p.district
          lat: p.latitude
          lng: p.longitude
          message: "#{p.wpt_code}\nStatus: #{p.status}"
