'use strict'

app = angular
  .module('taarifaWaterpointsApp', [
    'ui.bootstrap'
    'gridster',
    'ngResource',
    'ngRoute',
    'ngCookies',
    'dynform',
    'angular-flash.service',
    'angular-flash.flash-alert-directive',
    'geolocation',
    'gettext'
  ])

  .config ($routeProvider, $httpProvider, flashProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
        reloadOnSearch: false
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
      .when '/dashboard/national',
        templateUrl: 'views/natdashboard.html'
        controller: 'NationalDashboardCtrl'
      .when '/dashboard/regional',
        templateUrl: 'views/regdashboard.html'
        controller: 'RegionalDashboardCtrl'
      .otherwise
        redirectTo: '/'
    $httpProvider.defaults.headers.patch =
      'Content-Type': 'application/json;charset=utf-8'
    flashProvider.errorClassnames.push 'alert-danger'

  .filter('titlecase', () -> 
    return (s) -> 
      return s.toString().toLowerCase().replace( /\b([a-z])/g, (ch) -> return ch.toUpperCase()))

  .directive 'repeatDone', ($timeout) ->
    restrict: 'A'
    link: (scope, element, attr) ->
      if scope.$last
        $timeout ->
          scope.$emit (attr.repeatDone || 'repeat-done')
        , 100

  .run ($rootScope, flash) ->
    $rootScope.$on '$locationChangeSuccess', ->
      # Clear all flash messages on route change
      flash.info = ''
      flash.success = ''
      flash.warn = ''
      flash.error = ''
