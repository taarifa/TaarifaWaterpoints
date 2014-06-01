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
  .controller 'RequestTriageCtrl', ($scope, $http, Request, Waterpoint, flash) ->
    $scope.status = 'open'
    $scope.filterStatus = () ->
      Request.query where: {status: $scope.status}, (requests) ->
        $scope.requests = requests._items
        for r in requests._items
          Waterpoint.get where: {wpt_code: r.attribute.waterpoint_id}, (waterpoint) ->
            r.waterpoint = waterpoint._items[0]
          r.triage = {}
    $scope.triage = (request) ->
      $http
        method: 'PATCH'
        url: '/api/waterpoints/'+request.waterpoint._id
        data: request.triage
        headers: {'If-Match': request.waterpoint._etag}
      .success (data, status, headers, config) ->
        console.log data, status, headers, config
        if status == 200 and data._status == 'OK'
          flash.success = 'Waterpoint successfully updated!'
        if status == 200 and data._status == 'ERR'
          for field, message of data._issues
            flash.error = "#{field}: #{message}"
    $scope.filterStatus()

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
