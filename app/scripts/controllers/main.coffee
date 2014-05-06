'use strict'

angular.module('taarifaWaterpointsApp')
  .controller 'MainCtrl', ($scope, Waterpoint) ->
    $scope.waterpoints = Waterpoint.query()
  .controller 'MapCtrl', ($scope, Waterpoint) ->
    $scope.dar =
      lat: -6.7701973
      lng: 39.2664484
      zoom: 6
    $scope.markers = {}
    Waterpoint.query (waterpoints) ->
      for p in waterpoints
        $scope.markers[p._id] =
          group: p.district
          lat: p.latitude
          lng: p.longitude
          message: "#{p.wpt_code}\nStatus: #{p.status}"
