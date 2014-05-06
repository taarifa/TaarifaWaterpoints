'use strict'

apiResource = (resource, $resource) ->
  $resource "/api/#{resource}/:id"
  , {}
  , query:
      method: 'GET'
      isArray: true
      transformResponse: (data, headersGetter) ->
        JSON.parse(data)._items

angular.module('taarifaWaterpointsApp')
  .factory 'Waterpoint', ($resource) ->
    apiResource 'waterpoints', $resource
