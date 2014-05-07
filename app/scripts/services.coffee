'use strict'

apiResource = ($resource, resource, args) ->
  $resource "/api/#{resource}/:id"
  , # Default arguments
    args
  , # Override methods
    query:
      method: 'GET'
      isArray: false
    update:
      method: 'PUT'

angular.module('taarifaWaterpointsApp')
  .factory 'Waterpoint', ($resource) ->
    apiResource $resource, 'waterpoints',
      projection:
        _id: 1
        district: 1
        latitude: 1
        longitude: 1
        wpt_code: 1
        status: 1
