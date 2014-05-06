'use strict'

angular.module('taarifaWaterpointsApp')
  .controller 'MainCtrl', ($scope, Waterpoint) ->
    $scope.waterpoints = Waterpoint.query()
