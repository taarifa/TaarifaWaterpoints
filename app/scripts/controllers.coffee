'use strict'

angular.module('taarifaWaterpointsApp')

  .controller 'NavCtrl', ($scope, $location) ->
    $scope.location = $location

  .controller 'MainCtrl', ($scope, Waterpoint) ->
    Waterpoint.query (waterpoints) ->
      $scope.waterpoints = waterpoints._items

  .controller 'MapCtrl', ($scope, Map) ->
    $scope.map = Map

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

  .controller 'WaterpointEditCtrl', ($scope, $routeParams, Waterpoint, FacilityForm) ->
    $scope.wp = Waterpoint
    Waterpoint.get id: $routeParams.id, (waterpoint) ->
      $scope.form = waterpoint
    $scope.formTemplate = FacilityForm 'wpf001'
    $scope.save = () ->
      Waterpoint.update($routeParams.id, $scope.form)

  .controller 'RequestCreateCtrl', ($scope, $location, Request, RequestForm, flash) ->
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

  .controller 'RequestListCtrl', ($scope, Request) ->
    $scope.status = 'open'
    $scope.filterStatus = () ->
      query = if $scope.status then where: {status: $scope.status} else {}
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

  .controller 'DashboardCtrl', ($scope, $http) ->

    $scope.gridsterOpts = {
        margins: [10, 10],
        columns: 12,
        floating: true,
        pushing: true,
        draggable: {
            enabled: true
        },
        resizable: {
            enabled: true,
            stop: (event, uiWidget, $el) ->
                isplot = jQuery($el.children()[0]).hasClass("plot")
                if isplot then drawPlots()
        }
    };

    $scope.gridLayout = {
      tiles: [
          { sizeX: 2, sizeY: 2, row: 0, col: 0 },
          { sizeX: 2, sizeY: 2, row: 0, col: 2 },
          { sizeX: 2, sizeY: 2, row: 0, col: 4 },
      ],
      problems:
        { sizeX: 6, sizeY: 4, row: 2, col: 0 }
      map:
        { sizeX: 6, sizeY: 6, row: 0, col: 6 }
      filter:
        { sizeX: 12, sizeY: 1, row: 6, col: 0 }
      plots: [
        { sizeX: 12, sizeY: 5, row: 7, col: 0 },
        { sizeX: 12, sizeY: 5, row: 12, col: 0 }
        { sizeX: 12, sizeY: 5, row: 18, col: 0 }
      ]
    };


    $scope.plots = [
      {id:"statusSummary", title: "Functioning Waterpoints"},
      {id:"spendSummary", title: "Spend per Waterpoint"},
      {id:"spendImpact", title: "Spend vs Functionality"}]

    # FIXME: Are these the right groupings? Shouldn't hard code those...
    $scope.groups = ['region', 'lga', 'ward', 'funder', 'source_type']

    # default to region
    $scope.group = $scope.groups[0];

    $http.get('/api/waterpoints/values/region').success (data, status, headers, config) ->
      $scope.regions = data.sort()

    getLGA = () ->
      $http.get('/api/waterpoints/values/lga',
                params: {region: $scope.params?.region})
        .success (data, status, headers, config) ->
          $scope.lgas = data.sort()

    getWard = () ->
      $http.get('/api/waterpoints/values/ward',
                params:
                  region: $scope.params?.region
                  lga: $scope.params?.lga)
        .success (data, status, headers, config) ->
          $scope.wards = data.sort()

    # get the top 5 hardware problems
    getProblems = () ->
      $http.get('/api/waterpoints/stats_by/hardware_problem',
                params:
                  region: $scope.params?.region
                  lga: $scope.params?.lga
                  ward: $scope.params?.ward)
        .success (data, status, headers, config) ->
          $scope.problems = data.sort((a,b) ->
            return b.count - a.count
          )
          $scope.problems = $scope.problems.filter((x) ->
            x.hardware_problem != 'none').slice(0,5)

    $scope.getStatus = (changed) ->
      $http.get('/api/waterpoints/stats_by/status_group', params: $scope.params)
        .success (data, status, headers, config) ->
          total = d3.sum(data, (x) -> x.count)
          data.forEach( (x) -> x.percent = x.count / total * 100)

          # index by status_group for convenience
          statusMap = _.object(_.pluck(data,"status_group"), data)
          $scope.status = statusMap

          # ensure all three statusses are always represented
          empty = {count: 0, percent: 0}
          statusses = ["functional", "not functional", "needs repair"]
          statusses.forEach((x) -> statusMap[x] = statusMap[x] || empty)

          # the population covered
          # FIXME: needs pop data for percentage 
          funPop = statusMap.functional.waterpoints[0].population
          popCover = {count: funPop, percent: 0}

          $scope.tiles = _.pairs(_.pick(statusMap,'functional','needs repair'))
          $scope.tiles.push(['population cover', popCover])

      if changed == 'region'
        getLGA()
        getWard()
      if changed == 'lga'
        getWard()

      getProblems()
      drawPlots()

    $scope.groupBy = () ->
      drawPlots()

    drawPlots = () ->
      updatePlots($scope.params?.region, $scope.params?.lga, $scope.params?.ward, $scope.group)

    $scope.getStatus()
    getLGA()
    getWard()
    getProblems()
