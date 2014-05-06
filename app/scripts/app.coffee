'use strict'

angular
  .module('taarifaWaterpointsApp', [
    'ngResource',
    'ngRoute',
    'leaflet-directive',
    'dynform'
  ])
  .config ($routeProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MapCtrl'
      .otherwise
        redirectTo: '/'

