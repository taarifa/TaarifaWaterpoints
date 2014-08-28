'use strict'

app = angular
  .module('taarifaWaterpointsApp', [
    'ui.bootstrap'
    'gettext'
    'ui.router'
    'gridster'
    'ngResource'
    'ngCookies'
    'dynform'
    'angular-flash.service'
    'angular-flash.flash-alert-directive'
    'geolocation'
  ])

  .config ($stateProvider, $urlRouterProvider) ->
    $urlRouterProvider.otherwise("/")

    $stateProvider
      .state("home", {
        url: "/"
        templateUrl: "views/main.html"
        controller: 'HomeCtrl'
        reloadOnSearch: false
      })
      .state("waterpointsEdit", {
        url: "/waterpoints/edit/:id"
        templateUrl: "views/edit.html"
        controller: "WaterpointEditCtrl"
      })
      .state("waterpointsNew", {
        url: "/waterpoints/new"
        templateUrl: "views/edit.html"
        controller: "WaterpointCreateCtrl"
      })
      .state("requests", {
        url: "/requests?waterpoint_id"
        templateUrl: "views/requests.html"
        controller: "RequestListCtrl"
      })
      .state("requestsEdit", {
        url: "/requests/:id"
        templateUrl: "views/triage.html"
        controller: "RequestTriageCtrl"
      })
      .state("requestsNew", {
        url: "/requests/new?waterpoint_id"
        templateUrl: "views/triage.html"
        controller: "RequestTriageCtrl"
      })
      .state("dashboardNational", {
        url: "/dashboard/national"
        templateUrl: "views/natdashboard.html"
        controller: "NationalDashboardCtrl"
      })
      .state("dashboardRegional", {
        url: "/dashboard/regional"
        templateUrl: "views/regdashboard.html"
        controller: "RegionalDashboardCtrl"
      })

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

  .filter('titlecase', () ->
    return (s) ->
      return s.toString().toLowerCase().replace( /\b([a-z])/g, (ch) -> return ch.toUpperCase()))
