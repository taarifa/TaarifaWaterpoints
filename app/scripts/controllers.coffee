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
  .controller 'WaterpointEditCtrl', ($scope, $http, $routeParams, Waterpoint, FacilityForm, flash) ->
    Waterpoint.get id: $routeParams.id, (waterpoint) ->
      $scope.form = waterpoint
    $scope.formTemplate = FacilityForm 'wpf001'
    $scope.save = () ->
      etag = $scope.form._etag
      # We need to remove these special attributes since they are not defined
      # in the schema and the data will not validate and the update be rejected
      for attr in ['_created', '_etag', '_id', '_links', '_updated']
        $scope.form[attr] = undefined
      $http.put('/api/waterpoints/'+$routeParams.id,
                $scope.form,
                headers: {'If-Match': etag})
        .success (data, status, headers, config) ->
          console.log data, status, headers, config
          if status == 200 and data._status == 'OK'
            flash.success = 'Waterpoint successfully saved!'
          if status == 200 and data._status == 'ERR'
            for field, message of data._issues
              flash.error = "#{field}: #{message}"
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
      Request.query where: {status: $scope.status}, (requests) ->
        $scope.requests = requests._items
    $scope.filterStatus()
  .controller 'RequestTriageCtrl', ($scope, $http, $routeParams, $filter, Request, Waterpoint, flash) ->
    Request.get id: $routeParams.id, (request) ->
      if request.expected_datetime
        request.expected_datetime = new Date(request.expected_datetime)
      $scope.request = request
      Waterpoint.get where: {wpt_code: request.attribute.waterpoint_id}, (waterpoint) ->
        $scope.waterpoint = waterpoint._items[0]
    $scope.triage = {}
    $scope.doTriage = () ->
      if Object.keys($scope.triage).length
        $http
          method: 'PATCH'
          url: '/api/waterpoints/'+$scope.waterpoint._id
          data: $scope.triage
          headers: {'If-Match': $scope.waterpoint._etag}
        .success (data, status, headers, config) ->
          console.log data, status, headers, config
          if status == 200 and data._status == 'OK'
            flash.success = 'Waterpoint successfully updated!'
            for k, v of $scope.triage
              $scope.waterpoint[k] = v
            saveRequest()
          if status == 200 and data._status == 'ERR'
            for field, message of data._issues
              flash.error = "#{field}: #{message}"
      else
        saveRequest()
    saveRequest = () ->
      etag = $scope.request._etag
      # We need to remove these special attributes since they are not defined
      # in the schema and the data will not validate and the update be rejected
      for attr in ['_created', '_etag', '_id', '_links', '_updated']
        $scope.request[attr] = undefined
      if $scope.request.expected_datetime
        $scope.request.expected_datetime = $filter('date') $scope.request.expected_datetime, "EEE, dd MMM yyyy hh:mm:ss 'GMT'"
      $http.put('/api/requests/'+$routeParams.id,
                $scope.request,
                headers: {'If-Match': etag})
        .success (data, status, headers, config) ->
          console.log data, status, headers, config
          if status == 200 and data._status == 'OK'
            flash.success = 'Request successfully updated!'
          if status == 200 and data._status == 'ERR'
            for field, message of data._issues
              flash.error = "#{field}: #{message}"

  .controller 'DashboardCtrl', ($scope, $http) ->
    $scope.plots = [
      {id:"statusSummary", title: "Functioning Waterpoints"},
      {id:"spendSummary", title: "Spend per Waterpoint"},
      {id:"spendImpact", title: "Spend vs Functionality"}]
    # FIXME: Are these the right groupings? Shouldn't hard code those...

    $scope.groups = ['region', 'district', 'ward', 'funder', 'company', 'source_type']
    # default to region
    $scope.group = $scope.groups[0];

    $http.get('/api/waterpoints/values/region').success (data, status, headers, config) ->
      $scope.regions = data.sort()

    getDistrict = () ->
      $http.get('/api/waterpoints/values/district',
                params: {region: $scope.params?.region})
        .success (data, status, headers, config) ->
          $scope.districts = data.sort()

    getWard = () ->
      $http.get('/api/waterpoints/values/ward',
                params:
                  region: $scope.params?.region
                  district: $scope.params?.district)
        .success (data, status, headers, config) ->
          $scope.wards = data.sort()

    $scope.getStatus = (changed) ->
      $http.get('/api/waterpoints/status', params: $scope.params)
        .success (data, status, headers, config) ->
          #FIXME: manually add it so it shows up
          data.push(
            status: "Needs Repair"
            count: 0
          )
          total = d3.sum(data, (x) -> x.count)
          data.forEach( (x) -> x.percent = x.count / total * 100)

          $scope.status = data

          #FIXME: needs real data
          $scope.popCover = {count: Math.random()*10000, percent: Math.random()*100}

      if changed == 'region'
        getDistrict()
        getWard()
      if changed == 'district'
        getWard()
      updatePlots($scope.params?.region, $scope.params?.district, $scope.params?.ward, $scope.group)

    $scope.groupBy = () ->
      updatePlots($scope.params?.region, $scope.params?.district, $scope.params?.ward, $scope.group)

    $scope.getStatus()
    getDistrict()
    getWard()
