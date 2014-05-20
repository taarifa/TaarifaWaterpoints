'use strict'

angular.module('taarifaWaterpointsApp')
  .controller 'MainCtrl', ($scope, Waterpoint) ->
    Waterpoint.query (waterpoints) ->
      $scope.waterpoints = waterpoints._items
  .controller 'MapCtrl', ($scope, Map) ->
    $scope.map = Map
  .controller 'WaterpointCreateCtrl', ($scope, Waterpoint, Form, flash) ->
    $scope.formTemplate = Form 'wpf001'
    # FIXME: Should not hardcode the facility code here
    $scope.waterpoint =
      facility_code: "wpf001"
    $scope.save = () ->
      Waterpoint.save $scope.waterpoint, (waterpoint) ->
        console.log "Successfully created waterpoint", waterpoint
        if waterpoint._status == 'OK'
          flash.success = 'Waterpoint successfully created!'
  .controller 'WaterpointEditCtrl', ($scope, $http, $routeParams, Waterpoint, Form, flash) ->
    Waterpoint.get id: $routeParams.id, (waterpoint) ->
      $scope.waterpoint = waterpoint
    $scope.formTemplate = Form 'wpf001'
    $scope.save = () ->
      etag = $scope.waterpoint._etag
      # We need to remove these special attributes since they are not defined
      # in the schema and the data will not validate and the update be rejected
      for attr in ['_created', '_etag', '_id', '_links', '_updated']
        $scope.waterpoint[attr] = undefined
      $http.put('/api/waterpoints/'+$routeParams.id,
                $scope.waterpoint,
                headers: {'If-Match': etag})
        .success (data, status, headers, config) ->
          console.log data, status, headers, config
          if status == 200 and data._status == 'OK'
            flash.success = 'Waterpoint successfully saved!'
          if status == 200 and data._status == 'ERR'
            for field, message of data._issues
              flash.error = "#{field}: #{message}"
