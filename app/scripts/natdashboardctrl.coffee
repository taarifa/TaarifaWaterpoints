'use strict'

angular.module('taarifaWaterpointsApp')

  .controller 'NationalDashboardCtrl', ($scope, $http, $timeout, modalSpinner,
                                gettextCatalog, gettext, populationData, waterpointStats) ->

    # should http calls be cached
    # FIXME: should be application level setting
    cacheHttp = false

    # a flag to keep track if the plots should be redrawn
    # next time the tab is made visible
    plotsDirty = false

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
      map:
        { sizeX: 6, sizeY: 6, row: 0, col: 6 }
      problems:
        { sizeX: 6, sizeY: 4, row: 2, col: 0 }
      plots: [
        { sizeX: 12, sizeY: 5, row: 6, col: 0 },
        { sizeX: 6, sizeY: 5, row: 11, col: 0 }
        { sizeX: 6, sizeY: 5, row: 11, col: 6 }
      ]
    }


    $scope.plots = [
      {id:"statusSummary", title: gettext("Waterpoint status (ordered by % Functional)")},
      {id:"percFunLeaders", title: gettext("Performance Table: % Functional")},
      {id:"popReach", title: gettext("Performance Table: % Served")}]

    $scope.groups = ['region_name', 'district_name',
                     'ward_name', 'source_group',
                     'construction_year', 'quantity_group',
                     'quality_group', 'extraction_group',
                     'breakdown_year', 'payment_group', 'funder',
                     'installer', 'management', 'hardware_problem']

    # default group by to region
    $scope.params =
      group: $scope.groups[0]

    getRegion = () ->
      $http.get('/api/waterpoints/values/region_name', cache: cacheHttp)
        .success (data, status, headers, config) ->
          $scope.regions = data.sort()

    getWard = () ->
      modalSpinner.open()
      $http.get('/api/waterpoints/values/ward_name',
                cache: cacheHttp
                params:
                  region_name: $scope.params?.region
                  district_name: $scope.params?.district)
        .success (data, status, headers, config) ->
          $scope.wards = data.sort()
          modalSpinner.close()

    # get the top 5 hardware problems
    getProblems = () ->
      modalSpinner.open()
      $http.get('/api/waterpoints/stats_by/hardware_problem',
                cache: cacheHttp
                params:
                  region_name: $scope.params?.region
                  district_name: $scope.params?.district
                  ward_name: $scope.params?.ward)
        .success (data, status, headers, config) ->
          $scope.problems = data.sort((a,b) ->
            return b.count - a.count
          )
          $scope.problems = $scope.problems.filter((x) ->
            x.hardware_problem != 'none').slice(0,5)
          modalSpinner.close()

    lookupSelectedPop = () ->
      popData.lookup(
        $scope.params.region
        $scope.params.district
        $scope.params.ward)

    $scope.getStatus = () ->
      $scope.statusChoice = "all"

      modalSpinner.open()

      $http.get('/api/waterpoints/stats_by/status_group'
        cache: cacheHttp
        params:
          region_name: $scope.params.region
          district_name: $scope.params.district
          ward_name: $scope.params.ward)
        .success (data, status, headers, config) ->
          total = d3.sum(data, (x) -> x.count)
          data.forEach( (x) -> x.percent = x.count / total * 100)

          # index by status_group for convenience
          statusMap = _.object(_.pluck(data,"status_group"), data)
          $scope.status = statusMap

          # ensure all three statusses are always represented
          empty = {count: 0, percent: 0}
          statusses = [gettext("functional"), gettext("not functional"), gettext("needs repair")]
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
          $scope.tiles.push([gettext('population cover'), popCover])
          modalSpinner.close()

      getProblems()
      drawPlots()

    $scope.groupBy = () ->
      # the grouping field has changed, reset the selected status
      $scope.statusChoice = "all"
      drawPlots()

    $scope.drillDown = (fieldVal, fieldType, clearFilters) ->
      groupField = fieldType || $scope.params.group
      geoField = _.contains(['region_name','district_name','ward_name'], groupField)

      if !geoField then return

      gforder =
        region_name: "district_name"
        district_name: "ward_name"
        ward_name: "region_name"

      # Using timeout of zero instead of $scope.apply() in order to avoid
      # this error: https://docs.angularjs.org/error/$rootScope/inprog?p0=$apply
      # This happens, for example, when drillDown is called from the geojson feature
      # click handler
      # FIXME: a workaround, better solution?
      $timeout(() ->
        if !$scope.params then $scope.params = {}

        newgf = gforder[groupField]
        $scope.params.group = newgf

        if clearFilters || newgf == "region_name"
          $scope.params.region = null
          $scope.params.district = null
          $scope.params.ward = null

        if newgf == "region_name"
          $scope.getStatus()
        else
          # Note: groupField can be region_name or ward_name but
          # in the params object they are just called region or ward
          $scope.params[groupField.split("_")[0]] = fieldVal
          $scope.getStatus()
      ,0)

    barDblClick = (d) ->
      groupField = $scope.params.group
      $scope.drillDown(d[groupField])

    $scope.statusChoice = "all"
    $scope.statusColor = statusColor
    $scope.statusses = statusColor.domain().concat(["all"])

    # FIXME: for some reason this watch never gets triggered beyond first load...
    # resorting to ugly click event workaround
    # Note: using ngChange only paritally solves this. If you click
    # between radio buttons too quickly it stops working all together
    #$scope.$watch "statusChoice", (oldval, newval) ->
    #  console.log(oldval + "->" + newval)

    $scope.selectStatusClicked = (event) ->
      status = event.target.attributes.value.value
      $scope.statusChoice = status

      translate = (x) -> gettextCatalog.getString(x)
      region = $scope.params?.region
      district = $scope.params?.district
      ward = $scope.params?.ward
      groupfield = $scope.params?.group || "region_name"

      plotStatusSummary("#statusSummary", $scope.statusSumData, groupfield,
                        barDblClick, translate, status)

    drawPlots = () ->
      modalSpinner.open()

      translate = (s) -> gettextCatalog.getString(s)

      region = $scope.params?.region
      district = $scope.params?.district
      ward = $scope.params?.ward
      groupfield = $scope.params?.group || "region_name"
      status = $scope.statusChoice

      promise = waterpointStats.getStats(region, district, ward, groupfield, cacheHttp)
      promise.then( (data) ->

        # save a reference to the data so we have it when the selected status is changed
        $scope.statusSumData = data

        plotStatusSummary("#statusSummary", data, groupfield, barDblClick, translate, status)

        if _.contains(['region_name','district_name','ward_name'], groupfield)
          leaderChart("#percFunLeaders", data, groupfield, (x) -> x.percFun)

          data = _.sortBy(data, (x) -> -x.popReach)
          leaderChart("#popReach", data, groupfield, (x) -> x.popReach)

        plotsDirty = false
        modalSpinner.close())

    $scope.$on "gettextLanguageChanged", (e) ->
      # redraw the plots so axis labels, etc are translated

      # will only work if the tab is visible (else d3 fails)
      if $scope.dashTabs.national.active
        drawPlots()
      else
        # we have to remember to redraw the plots when the tab
        # finally does become active
        plotsDirty = true

    $scope.$watch "dashTabs.national.active", (val) ->
      if val and plotsDirty
        drawPlots()

    # access object to the population data
    # FIXME: better handled by a $resource perhaps?
    popData = null

    initView = () ->
      populationData.then((data) ->
        popData = data
        $scope.getStatus())

      getProblems()

    initView()
