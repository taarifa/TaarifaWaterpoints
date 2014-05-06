'use strict'

apiResource = (resource, $resource) ->
  $resource "/api/#{resource}/:id"
  , {}
  , query:
      method: 'GET'
      isArray: false

angular.module('taarifaWaterpointsApp')
  .factory 'Waterpoint', ($resource) ->
    apiResource 'waterpoints', $resource
