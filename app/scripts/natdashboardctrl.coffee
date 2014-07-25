'use strict'

angular.module('taarifaWaterpointsApp')

  .controller 'DashboardCtrl', ($scope, $http, modalSpinner, populationData) ->

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
    }

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
        { sizeX: 6, sizeY: 5, row: 12, col: 0 }
        { sizeX: 6, sizeY: 5, row: 18, col: 6 }
      ]
    }


    $scope.plots = [
      {id:"statusSummary", title: "Waterpoint status (ordered by % Functional)"},
      {id:"percFunLeaders", title: "Leaderboard: Percentage Functional"},
      {id:"popReach", title: "Leaderboard: Percentage of the Population Served"}]

    $scope.groups = ['region', 'lga', 'ward', 'funder', 'source_type',
                     'construction_year', 'quantity_group',
                     'quality_group', 'extraction_type_group',
                     'breakdown_year', 'payment_type', 'funder',
                     'installer', 'management', 'hardware_problem']

    # default group by to region
    $scope.params =
      group: $scope.groups[0]

    $http.get('/api/waterpoints/values/region').success (data, status, headers, config) ->
      $scope.regions = data.sort()

    getLGA = () ->
      $http.get('/api/waterpoints/values/lga',
                params: {region: $scope.params?.region})
        .success (data, status, headers, config) ->
          $scope.lgas = data.sort()

    getWard = () ->
      modalSpinner.open()
      $http.get('/api/waterpoints/values/ward',
                params:
                  region: $scope.params?.region
                  lga: $scope.params?.lga)
        .success (data, status, headers, config) ->
          $scope.wards = data.sort()
          modalSpinner.close()

    # get the top 5 hardware problems
    getProblems = () ->
      modalSpinner.open()
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
          modalSpinner.close()

    lookupSelectedPop = () ->
      # FIXME: we do not have pop data for LGAs!
      popData.lookup(
        $scope.params.region
        $scope.params.lga
        $scope.params.ward)

    $scope.getStatus = (changed) ->
      modalSpinner.open()

      $http.get('/api/waterpoints/stats_by/status_group', params: _.omit($scope.params,'group'))
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
          if statusMap.functional.waterpoints
            funPop = statusMap.functional.waterpoints[0].population
          else
            # will happen for an invalid selection
            funPop = 0

          pop = lookupSelectedPop()
          percent = if pop > 0 then funPop/pop*100 else "unknown"

          popCover = {count: funPop, percent: percent}

          $scope.tiles = _.pairs(_.pick(statusMap,'functional','needs repair'))
          $scope.tiles.push(['population cover', popCover])
          modalSpinner.close()

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
      modalSpinner.open()

      region = $scope.params?.region
      lga = $scope.params?.lga
      ward = $scope.params?.ward
      groupfield = $scope.params?.group || "region"

      url = "/api/waterpoints/stats_by/" + groupfield
      filterFields = {"region":region, "lga":lga, "ward":ward}
      filters = []

      _.keys(filterFields).forEach((x) ->
        if filterFields[x] then filters.push(x + "=" + filterFields[x]))

      filter = filters.join("&")

      if filter then url += "?" + filter

      d3.json(url, (error, data) ->
        geoField = _.contains(['region','lga','ward'], groupfield)

        data.forEach((x) ->
          f = _.find(x.waterpoints, isFunctional)

          # ensure there is always a functional entry
          if !f
            f = {
              status: "functional",
              population: 0,
              count: 0
            }
            x.waterpoints.push(f)

          x.percFun = f.count / x.count * 100

          x.popReach = 0

          if geoField
            pop = popData.lookup(
              if groupfield == "region" then x[groupfield] else null,
              if groupfield == "lga" then x[groupfield] else null,
              if groupfield == "ward" then x[groupfield] else null
            )
            if pop > 0
              x.popReach = f.population / pop * 100
        )

        # sort by % functional waterpoints
        data = _.sortBy(data, (x) -> -x.percFun)

        plotStatusSummary("#statusSummary", data, groupfield, $scope)

        if _.contains(['region','lga','ward'], groupfield)
          leaderChart("#percFunLeaders", data, groupfield, (x) -> x.percFun)

          data = _.sortBy(data, (x) -> -x.popReach)
          leaderChart("#popReach", data, groupfield, (x) -> x.popReach)

         modalSpinner.close()
      )

    ####################################################
    # Initialization code

    # FIXME: is this the proper way of doing things?
    popData = null
    populationData.then((data) ->
      popData = data
      $scope.getStatus())

    getLGA()
    getWard()
    getProblems()
