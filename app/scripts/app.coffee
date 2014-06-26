'use strict'

app = angular
  .module('taarifaWaterpointsApp', [
    'ui.router',
    'ui.bootstrap',
    'gridster',
    'ngResource',
    'ngRoute',
    'leaflet-directive',
    'dynform',
    'angular-flash.service',
    'angular-flash.flash-alert-directive',
    'gettext'
  ])

  .config ($urlRouterProvider, $httpProvider, flashProvider, $stateProvider) ->
    $urlRouterProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MapCtrl'
      .when '/waterpoints/edit/:id',
        templateUrl: 'views/edit.html'
        controller: 'WaterpointEditCtrl'
      .when '/waterpoints/new',
        templateUrl: 'views/edit.html'
        controller: 'WaterpointCreateCtrl'
      .when '/requests',
        templateUrl: 'views/requests.html'
        controller: 'RequestListCtrl'
      .when '/requests/new',
        templateUrl: 'views/edit.html'
        controller: 'RequestCreateCtrl'
      .when '/requests/:id',
        templateUrl: 'views/triage.html'
        controller: 'RequestTriageCtrl'
      .when '/dashboard',
        templateUrl: 'views/dashboard.html'
      .otherwise
        redirectTo: '/'
    $httpProvider.defaults.headers.patch =
      'Content-Type': 'application/json;charset=utf-8'
    flashProvider.errorClassnames.push 'alert-danger'

    $stateProvider\
      .state('national', {
        url: "/dashboard/national",
        views: {
          "nationalView": {
            templateUrl: "views/dashboard-national.html",
            controller: 'DashboardCtrl'
          }
        }
      })
      .state('regional', {
        url: "/regional",
        views: {
          "nationalView": {
            templateUrl: "views/dashboard-regional.html",
            controller: 'DCPlotsCtrl'
          }
        }
      })


  .filter('titlecase', () ->
    return (s) -> 
      return s.toString().toLowerCase().replace( /\b([a-z])/g, (ch) -> return ch.toUpperCase()))

  .run (gettextCatalog,$rootScope) ->
    gettextCatalog.currentLanguage = 'en'
    $rootScope.fields =
      catalog: gettextCatalog
      languages:
        en: "English"
        sw_TZ: "Swahili"
