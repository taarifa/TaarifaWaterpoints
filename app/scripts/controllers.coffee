'use strict'

angular.module('taarifaWaterpointsApp')
  .controller 'MainCtrl', ($scope, Waterpoint) ->
    Waterpoint.query (waterpoints) ->
      $scope.waterpoints = waterpoints._items
  .controller 'MapCtrl', ($http, $scope, Waterpoint) ->
    $scope.dar =
      lat: -6.7701973
      lng: 39.2664484
      zoom: 6
    $scope.markers = {}
    addMarkers = (waterpoints) ->
      for p in waterpoints._items
        $scope.markers[p._id] =
          group: p.district
          lat: p.latitude
          lng: p.longitude
          message: "#{p.wpt_code}<br />Status: #{p.status}"
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
        latitude: 1
        longitude: 1
        wpt_code: 1
        status: 1
    , addMarkers
