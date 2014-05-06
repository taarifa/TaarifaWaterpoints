'use strict'

angular
  .module('taarifaWaterpointsApp', [
    'ngResource',
    'ngRoute',
    'leaflet-directive'
  ])
  .config ($routeProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
      .otherwise
        redirectTo: '/'

