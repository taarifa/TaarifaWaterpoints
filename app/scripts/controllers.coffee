'use strict'

angular.module('taarifaWaterpointsApp')

  .controller 'NavCtrl', ($scope, $location) ->
    $scope.location = $location

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

  .controller 'MainCtrl', ($scope, $http, $location, Waterpoint, Map, flash, gettext) ->
    map = Map "wpMap", showScale:true
    $scope.where = $location.search()
    $scope.where.max_results = parseInt($scope.where.max_results) || 100
    $scope.where.reports_only = parseInt($scope.where.reports_only) || 0
    $http.get('/api/waterpoints/values/region_name', cache: true).success (regions) ->
      $scope.regions = regions
    $http.get('/api/waterpoints/values/district_name', cache: true).success (districts) ->
      $scope.districts = districts

    $scope.resetParameters = ->
      $scope.where = 
        max_results: 100
        reports_only: 0
      $http.get('/api/waterpoints/values/region_name', cache: true).success (regions) ->
        $scope.regions = regions
      $http.get('/api/waterpoints/values/district_name', cache: true).success (districts) ->
        $scope.districts = districts

    $scope.clearDistrict = ->
      $scope.where.district_name = null
      $location.search 'district_name', null

    $scope.updateMap = (nozoom) ->
      $location.search($scope.where)
      where = {}
      if $scope.where.region_name
        where.region_name = $scope.where.region_name
        # Filter districts based on selected Region
        $http.get('/api/waterpoints/values/district_name', params: {region_name: where.region_name}, cache: true).success (districts) ->
          $scope.districts = districts
      else
        $http.get('/api/waterpoints/values/district_name', cache: true).success (districts) ->
            $scope.districts = districts
      if $scope.where.district_name
        where.district_name = $scope.where.district_name
      if $scope.where.status_group
        where.status_group = $scope.where.status_group
      if $scope.where.reports_only
        $http.get('/api/waterpoints/requests').success (requests) ->
          where.wptcode = "$in": requests
          query where, $scope.where.max_results, nozoom
      else
        query where, $scope.where.max_results, nozoom

    $scope.reset = ->
      $scope.resetParameters()
      $scope.updateMap()

    query = (where, max_results, nozoom) ->
      map.clearMarkers()
      Waterpoint.query
        max_results: max_results
        where: where
        projection:
          _id: 1
          district_name: 1
          location: 1
          wptcode: 1
          status_group: 1
        strip: 1
      , (waterpoints) ->
        if waterpoints._items.length == 0
          flash.info = gettext('No waterpoints match your filter criteria!')
          return
        map.addWaterpoints(waterpoints._items)
        map.zoomToMarkers() unless nozoom
    $scope.updateMap()

  .controller 'DashboardCtrl', ($scope) ->
    $scope.dashTabs =
      national:
        active: true
      regional:
        active: false

  .controller 'ModalSpinnerCtrl', ($modal, $scope, msg, status) ->
    $scope.spinnerDialog = msg
    $scope.spinnerStatus = status

  .controller 'WaterpointCreateCtrl', ($scope, Waterpoint, FacilityForm,
                                        Map, flash, gettext, geolocation, modalSpinner) ->
    $scope.formTemplate = FacilityForm 'wpf001'
    # Default to today
    d = new Date()
    today = d.toGMTString()

    # FIXME: Should not hardcode the facility code here
    $scope.form =
      facility_code: "wpf001"
      date_recorded: today

    modalSpinner.open(" ", "Finding your location...")
    geolocation.getLocation().then (data) ->
      modalSpinner.close()
      flash.success = gettext("Geolocation succeeded: got coordinates") + " #{data.coords.longitude.toPrecision(4)}, #{data.coords.latitude.toPrecision(4)}"
      $scope.form.location = coordinates: [data.coords.longitude, data.coords.latitude]
      map = Map("editMap", {})
      map.clearMarkers()
      map.addWaterpoints([$scope.form])
      map.zoomToMarkers()
    , (reason) ->
      flash.error = gettext("Geolocation failed:") + " #{reason}"
    $scope.save = () ->
      Waterpoint.save $scope.form, (waterpoint) ->
        if waterpoint._status == 'OK'
          console.log "Successfully created waterpoint", waterpoint
          flash.success = gettext('Waterpoint successfully created!')
        if waterpoint._status == 'ERR'
          console.log gettext("Failed to create waterpoint"), waterpoint
          for field, message of waterpoint._issues
            flash.error = "#{field}: #{message}"

  .controller 'WaterpointEditCtrl', ($scope, $routeParams,
                                    Map, Waterpoint, FacilityForm) ->
    $scope.wp = Waterpoint

    map = Map("editMap", {})

    Waterpoint.get id: $routeParams.id, (waterpoint) ->
      # We are editing a waterpoint so set the date_recorded
      # field to today, should it be saved.
      d = new Date()
      waterpoint.date_recorded = d.toGMTString()

      $scope.form = waterpoint
      map.clearMarkers()
      map.addWaterpoints([waterpoint])
      map.zoomToMarkers()

    $scope.formTemplate = FacilityForm 'wpf001'
    $scope.save = () ->
      Waterpoint.update($routeParams.id, $scope.form)

  .controller 'RequestCreateCtrl', ($scope, $location, $routeParams, Request, gettext,
                                    $timeout, Waterpoint, Map, RequestForm, flash) ->
    map = Map("editMap")

    Waterpoint.get where: {wptcode: $routeParams.waterpoint_id}, (wp) ->
      map.clearMarkers()
      # FIXME: assumes wptcode is unique!
      map.addWaterpoints([wp._items[0]])
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
          flash.success = gettext('Request successfully created!')
        if request._status == 'ERR'
          console.log "Failed to create request", request
          for field, message of request._issues.attribute
            flash.error = "#{field}: #{message}"

  .controller 'RequestListCtrl', ($scope, $location, Request, flash, gettext) ->
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
        if $scope.requests.length == 0
          flash.info = gettext("No request matching the criteria!")
    $scope.filterStatus()

  .controller 'RequestTriageCtrl', ($scope, $routeParams, $filter,
                                    Request, Waterpoint, flash, gettext) ->
    $scope.apply = {}
    Request.get id: $routeParams.id, (request) ->
      if request.expected_datetime
        $scope.expected_datetime = new Date(request.expected_datetime)
      $scope.request = request
      Waterpoint.get where: {wptcode: request.attribute.waterpoint_id}, (waterpoint) ->
        $scope.waterpoint = waterpoint._items[0]
        if not request.agency_responsible
          request.agency_responsible = $scope.waterpoint.management
    $scope.saveRequest = () ->
      d = {}
      for key of $scope.apply
        d[key] = $scope.request.attribute[key]
      Waterpoint.patch($scope.waterpoint._id, d, $scope.waterpoint._etag)
      .success (data, status) ->
        if status == 200 and data._status == 'OK'
          flash.success = gettext('Waterpoint successfully updated!')
          $scope.waterpoint._etag = data._etag
          for key of $scope.apply
            $scope.waterpoint[key] = $scope.request.attribute[key]
          $scope.apply = {}
          if $scope.expected_datetime
            $scope.request.expected_datetime = $filter('date') $scope.expected_datetime, "EEE, dd MMM yyyy hh:mm:ss 'GMT'"
          Request.update($routeParams.id, $scope.request)
        if status == 200 and data._status == 'ERR'
          for field, message of data._issues
            flash.error = "#{field}: #{message}"
