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
    apiResource $resource, 'waterpoints'
  .factory 'Facility', ($resource) ->
    apiResource $resource, 'facilities'
