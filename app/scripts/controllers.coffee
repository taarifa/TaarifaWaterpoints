'use strict'

angular.module('taarifaWaterpointsApp')

  .controller 'NavCtrl', ($scope, $location) ->
    $scope.location = $location

  .controller 'MainCtrl', ($scope, Waterpoint) ->
    Waterpoint.query (waterpoints) ->
      $scope.waterpoints = waterpoints._items

  .controller 'LocaleCtrl', ($scope, $cookies, $rootScope, gettextCatalog) ->
    # get the current language from the cookie if available
    $cookies.locale = 'en' unless !!$cookies.locale
    gettextCatalog.currentLanguage = $cookies.locale

    # Save the catalog on the root scope so others can access it
    # e.g., in event handler
    # FIXME: feels clunky, surprised you cant get at it from the event obj
    $rootScope.langCatalog = gettextCatalog

    $scope.languages =
      current: gettextCatalog.currentLanguage
      available:
        en: "English"
        sw_TZ: "Swahili"

    $scope.$watch "languages.current", (lang) ->
      if not lang then return
      # Update the cookie
      $cookies.locale = lang
      # Using the setter function ensures the gettextLanguageChanged event gets fired
      gettextCatalog.setCurrentLanguage(lang)

  .controller 'MapCtrl', ($scope, $http, $location, Waterpoint, Map) ->
    map = Map "wpMap"
    $scope.where = $location.search()
    $scope.where.max_results = parseInt($scope.where.max_results) || 100
    $scope.where.reports_only = parseInt($scope.where.reports_only) || 0
    $http.get('/api/waterpoints/values/region', cache: true).success (regions) ->
      $scope.regions = regions
    $scope.updateMap = () ->
      $location.search($scope.where)
      where = {}
      if $scope.where.region
        where.region = $scope.where.region
      if $scope.where.status_group
        where.status_group = $scope.where.status_group
      if $scope.where.reports_only
        $http.get('/api/waterpoints/requests', cache: true).success (requests) ->
          where.wpt_code = "$in": requests
          query where, $scope.where.max_results
      else
        query where, $scope.where.max_results
    query = (where, max_results) ->
      map.clearMarkers()
      Waterpoint.query
        max_results: max_results
        where: where
        projection:
          _id: 1
          district: 1
          location: 1
          wpt_code: 1
          status_group: 1
        strip: 1
      , (waterpoints) ->
        for p in waterpoints._items
          popup = map.makePopup(p)
          map.addWaterpoint p, popup
        map.zoomToMarkers()
    $scope.updateMap()

  .controller 'DashboardCtrl', ($scope) ->
    $scope.dashTabs =
      national:
        active: true
      regional:
        active: false

  .controller 'WaterpointCreateCtrl', ($scope, Waterpoint, FacilityForm, flash) ->
    $scope.formTemplate = FacilityForm 'wpf001'
    # FIXME: Should not hardcode the facility code here
    $scope.form =
      facility_code: "wpf001"
    $scope.save = () ->
      Waterpoint.save $scope.form, (waterpoint) ->
        if waterpoint._status == 'OK'
          console.log "Successfully created waterpoint", waterpoint
          flash.success = 'Waterpoint successfully created!'
        if waterpoint._status == 'ERR'
          console.log "Failed to create waterpoint", waterpoint
          for field, message of waterpoint._issues
            flash.error = "#{field}: #{message}"

  .controller 'WaterpointEditCtrl', ($scope, $routeParams,
                                    Map, Waterpoint, FacilityForm) ->
    $scope.wp = Waterpoint

    map = Map("editMap")

    Waterpoint.get id: $routeParams.id, (waterpoint) ->
      $scope.form = waterpoint
      map.clearMarkers()
      map.addWaterpoint(waterpoint)
      map.zoomToMarkers()

    $scope.formTemplate = FacilityForm 'wpf001'
    $scope.save = () ->
      Waterpoint.update($routeParams.id, $scope.form)

  .controller 'RequestCreateCtrl', ($scope, $location, $routeParams, Request, 
                                    $timeout, Waterpoint, Map, RequestForm, flash) ->
    map = Map("editMap")

    Waterpoint.get where: {wpt_code: $routeParams.waterpoint_id}, (wp) ->
      map.clearMarkers()
      # FIXME: assumes wpt_code is unique!
      map.addWaterpoint(wp._items[0])
      map.zoomToMarkers()

    $scope.formTemplate = RequestForm 'wps001', $location.search()
    # FIXME: Should not hardcode the service code here
    $scope.form = {}
    $scope.save = () ->
      form =
        service_code: "wps001"
        attribute: $scope.form
      Request.save form, (request) ->
        if request._status == 'OK'
          console.log "Successfully created request", request
          flash.success = 'Request successfully created!'
        if request._status == 'ERR'
          console.log "Failed to create request", request
          for field, message of request._issues.attribute
            flash.error = "#{field}: #{message}"

  .controller 'RequestListCtrl', ($scope, $location, Request) ->
    $scope.where = $location.search()
    $scope.filterStatus = () ->
      $location.search($scope.where)
      query = where: {}
      if $scope.where.status
        query.where.status = $scope.where.status
      if $scope.where.status_group
        query.where['attribute.status_group'] = $scope.where.status_group
      if $scope.where.waterpoint_id
        query.where['attribute.waterpoint_id'] = $scope.where.waterpoint_id
      Request.query query, (requests) ->
        $scope.requests = requests._items
    $scope.filterStatus()

  .controller 'RequestTriageCtrl', ($scope, $routeParams, $filter, Request, Waterpoint, flash) ->
    Request.get id: $routeParams.id, (request) ->
      if request.expected_datetime
        $scope.expected_datetime = new Date(request.expected_datetime)
      $scope.request = request
      Waterpoint.get where: {wpt_code: request.attribute.waterpoint_id}, (waterpoint) ->
        $scope.waterpoint = waterpoint._items[0]
        if not request.agency_responsible
          request.agency_responsible = $scope.waterpoint.management
    $scope.apply = (key) ->
      d = {}
      d[key] = $scope.request.attribute[key]
      Waterpoint.patch($scope.waterpoint._id, d, $scope.waterpoint._etag)
      .success (data, status) ->
        if status == 200 and data._status == 'OK'
          flash.success = 'Waterpoint successfully updated!'
          $scope.waterpoint._etag = data._etag
          $scope.waterpoint[key] = $scope.request.attribute[key]
        if status == 200 and data._status == 'ERR'
          for field, message of data._issues
            flash.error = "#{field}: #{message}"
    $scope.saveRequest = () ->
      if $scope.expected_datetime
        $scope.request.expected_datetime = $filter('date') $scope.expected_datetime, "EEE, dd MMM yyyy hh:mm:ss 'GMT'"
      Request.update($routeParams.id, $scope.request)

