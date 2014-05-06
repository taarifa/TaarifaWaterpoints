'use strict'

apiResource = (resource, $resource) ->
  $resource "/api/#{resource}/:id"
  , # Default arguments
    projection:
      _id: 1
      district: 1
      latitude: 1
      longitude: 1
      wpt_code: 1
      status: 1
  , # Override methods
    query:
      method: 'GET'
      isArray: false

angular.module('taarifaWaterpointsApp')
  .factory 'Waterpoint', ($resource) ->
    apiResource 'waterpoints', $resource
