angular.module('taarifaWaterpointsApp')

  .controller 'DCPlotsCtrl', ($scope, $http, $q, modalSpinner, populationData) ->
    $scope.gridsterOpts =
      margins: [10, 10]
      columns: 12
      floating: true
      pushing: true
      draggable:
        enabled: true
        handle: '.panel-heading'
      resizable:
        enabled: false

    $scope.gridLayout =
      statusPerLga: { sizeX: 6, sizeY: 4, row: 0, col: 0, title: "Functionality by LGA" }
      topProblems: { sizeX: 6, sizeY: 4, row: 0, col: 6, title: "Top Problems"}

      constrYear: { sizeX: 6, sizeY: 3, row: 4, col: 0, title: "Construction Year" }
      breakYear: { sizeX: 6, sizeY: 3, row: 4, col: 6, title: "Breakdown Year" }

      statusPerWard: { sizeX: 12, sizeY: 5, row: 7, col: 0, title: "Functionality by Ward" }

      statusPie: { sizeX: 3, sizeY: 3, row: 12, col: 0, title: "Functionality" }
      qualityPie: { sizeX: 3, sizeY: 3, row: 12, col: 3, title: "Water Quality" }
      quantityPie: { sizeX: 3, sizeY: 3, row: 12, col: 6, title: "Water Quantity" }
      extractionPie: { sizeX: 3, sizeY: 3, row: 12, col: 9, title: "Extraction Type" }

      costImpactBubble: { sizeX: 12, sizeY: 4, row: 15, col: 0, title: "Functionality vs Cost" }

      paymentPie: { sizeX: 3, sizeY: 3, row: 19, col: 0, title: "Payment Method" }
      managementPie: { sizeX: 3, sizeY: 3, row: 19, col: 3, title: "Management" }
      funderPie: { sizeX: 3, sizeY: 3, row: 19, col: 6, title: "Funder" }
      installerPie: { sizeX: 3, sizeY: 3, row: 19, col: 9, title: "Installer" }

      statusPerManagement: { sizeX: 6, sizeY: 4, row: 22, col: 0, title: "Functionality by Management" }
      statusPerExtraction: { sizeX: 6, sizeY: 4, row: 22, col: 6, title: "Functionality by Extraction" }

    $scope.fields = ["status_group", "lga", "ward",
                 "source_type", "amount_tsh", "population"
                 "construction_year", "quantity_group",
                 "quality_group", "extraction_type_group",
                 "breakdown_year", "payment_type", "funder",
                 "installer", "management", "hardware_problem"]

    dimensions = []
    xfilter = null
    popData = null
    $scope.tabs =
      regcharts:
        active: true
      regtable:
        active: false

    # Called when the tab is activated for the first time
    # Has to be done on tab activation for else the charts can not pickup
    # the correct dimensions from their containing elements.
    $scope.initView = () ->
      # only do once
      if dc.chartRegistry.list().length then return

      modalSpinner.open()

      # get all regions
      $http
        .get('/api/waterpoints/values/region')
        .success (data, status, headers, config) ->
          $scope.regions = data.sort()
          $scope.region = $scope.regions[3]

          # FIXME:
          # unfortunately, for some reason, not all dc charts manage to pickup the
          # correct dimensions on their own. Manually set a resize renderlet to run once
          # all the charts have rendered.
          dc.renderlet () ->
            resizeCharts()
            modalSpinner.close()
            # only keep the renderlet once
            dc.renderlet null

          # ensure we have the population data
          populationData.then (data) ->
            popData = data
            setupCharts $scope.region

    # what value to use for year 0
    YEAR_ZERO=1950

    getData = (region, callback) ->
      filter =  region: region

      ones = Array
        .apply(null, new Array($scope.fields.length))
        .map(Number.prototype.valueOf, 1)
      projection = _.object($scope.fields, ones)

      #FIXME: eventually load page by page to improve responsiveness
      url = "/api/waterpoints?where=" + JSON.stringify(filter) +
              "&projection=" + JSON.stringify(projection) +
              "&max_results=10000"

      $q.all([
        $http.get(url, cache: true)
      ]).then((results) ->
        waterpoints = results[0].data._items

        waterpoints.forEach (d) ->
          d.breakdown_year = new Date(d.breakdown_year || YEAR_ZERO, 0, 1)
          d.construction_year = new Date(d.construction_year || YEAR_ZERO, 0, 1)

        callback waterpoints)

    createDim = (f) ->
      dim = xfilter.dimension(f)
      dimensions.push(dim)
      dim

    $scope.$on "$locationChangeStart", (event, nextLocation, currentLocation) ->
      # make sure we properly cleanup the global dc object when leaving the page
      # otherwise causes problems when we come back to it
      destroyCharts()

    destroyCharts = () ->
      # Just return if the regional charts were never loaded
      if !xfilter then return

      # get all charts
      charts = dc.chartRegistry.list()

      # clear the filters on all charts
      dc.filterAll()

      # clear the filters on all dimensions
      dimensions.forEach (d) -> d.filter(null)

      # no more filters, remove all the data
      xfilter.remove()

      # destroy the filters
      dimensions.forEach (d) -> d.dispose()
      dimensions = []

      charts.forEach (c) ->
        c.expireCache()

      dc.deregisterAllCharts()

    # FIXME: see next comment
    $scope.rerenderCharts = () ->
      modalSpinner.open()

      # Make sure we switch to the charts tab
      # or else they are not going to render correctly
      # when out of view
      # FIXME: better solution?
      $scope.tabs.regtable.active = false
      $scope.tabs.regcharts.active = true

      destroyCharts()

      # FIXME: see above comment
      dc.renderlet () ->
        resizeCharts()
        modalSpinner.close()
        # only keep the renderlet once
        dc.renderlet null

      # simply recreate all charts
      setupCharts $scope.region

    # FIXME: this should be the correct way of replacing
    # data. However, data in the groups/dims is properly
    # updated but dc.js is not updating the chart properly
    # to reflect the backed data.
    $scope.rerenderCharts2 = () ->
      # clear the filters on all charts
      dc.filterAll()

      # no more filters, remove all the data
      xfilter.remove()

      # get and set the new data
      getData $scope.region, (data) ->
        xfilter.add data

        charts = dc.chartRegistry.list()
        charts.forEach (c) ->
          c.expireCache()
        dc.renderAll()

    # redraw the charts taking the new dimensions from the
    # containing element
    resizeCharts = () ->
      charts = dc.chartRegistry.list()
      charts.forEach (c) ->
        a = c.anchor()
        d = getDimensions(a,10,65)
        c.width(d.w)
        c.height(d.h)
        if c.radius then c.radius((d.w / 2) - 30)
        c.render()

    $scope.$on 'gridster-resized', (newSizes) ->
      newWidth = newSizes[0]
      newHeight = newSizes[1]
      resizeCharts()

    $scope.initTable = () ->
      # needed to fix table alignment if drawn when not visible
      table = $("#dc-data-table").dataTable()
      table.fnAdjustColumnSizing()

    setupCharts = (region) ->
      getData region, (data) ->
        statusPerLgaChart = dc.barChart("#statusPerLga")
        statusPerWardChart = dc.barChart("#statusPerWard")
        constrYearChart = dc.barChart("#constrYear")
        breakYearChart = dc.barChart("#breakYear")
        quantityChart = dc.pieChart("#quantityPie")
        qualityChart = dc.pieChart("#qualityPie")
        extractionChart = dc.pieChart("#extractionPie")
        statusChart = dc.pieChart("#statusPie")
        paymentChart = dc.pieChart("#paymentPie")
        installerChart = dc.pieChart("#installerPie")
        funderChart = dc.pieChart("#funderPie")
        managementChart = dc.pieChart("#managementPie")
        statusPerExtraction = dc.barChart("#statusPerExtraction")
        statusPerManagement = dc.barChart("#statusPerManagement")
        costImpactBubbleChart = dc.bubbleChart("#costImpactBubble")
        problemsChart = dc.rowChart("#topProblems")

        # create Crossfilter Dimensions and Groups
        xfilter = crossfilter data
        all = xfilter.groupAll()

        lgas = createDim (d) -> d.lga
        statusPerLga = reduceStatus lgas.group()

        wards = createDim (d) -> d.ward
        statusPerWard = reduceStatus wards.group()

        constrYears = createDim (d) -> d.construction_year
        constrYearsGroup = reduceStatus constrYears.group()

        breakYears = createDim (d) -> d.breakdown_year
        breakYearsGroup = reduceStatus breakYears.group()

        quantities = createDim (d) -> d.quantity_group
        quantityStatusGroup = reduceStatus quantities.group()

        installers = createDim (d) -> d.installer
        installersGroup = installers.group()
        installersStatusGroup = reduceStatus installers.group()

        funders = createDim (d) -> d.funder
        fundersGroup = funders.group()
        fundersStatusGroup = reduceStatus funders.group()

        qualities = createDim (d) -> d.quality_group
        qualitiesStatusGroup = reduceStatus qualities.group()

        extractionTypes = createDim (d) -> d.extraction_type_group
        extractionStatusGroup = reduceStatus extractionTypes.group()

        statuses = createDim (d) -> d.status_group
        statusGroup = statuses.group()

        managements = createDim (d) -> d.management
        managementsGroup = managements.group()
        managementsStatusGroup = reduceStatus managements.group()

        statuses = createDim (d) -> d.status_group
        statusGroup = statuses.group()

        paymentTypes = createDim (d) -> d.payment_type
        paymentGroup = paymentTypes.group()

        problems = createDim((d) -> d.hardware_problem)
        problemsGroup = problems.group()

        amounts = createDim (d) -> d.amount_tsh
        costStatusGroup = reduceCostStatus wards.group()

        statusBarChart statusPerLgaChart, lgas, statusPerLga, 15
        statusBarChart statusPerExtraction, extractionTypes, extractionStatusGroup
        statusBarChart statusPerManagement, managements, managementsStatusGroup
        statusBarChart statusPerWardChart, wards, statusPerWard, 1

        rowChart problemsChart, problems, problemsGroup

        bubbleChart costImpactBubbleChart, wards, costStatusGroup,
                    (d) -> d.key,             # color
                    (d) -> d.value.percFun,   # key (x)
                    (d) -> d.value.avgCost,   # value (y)
                    (d) -> d.value.pop,       # radius
                    "% Functional",           # x label
                    "Average Payment"         # y label

        yearChart constrYearChart, constrYears, constrYearsGroup, "Construction Year"
        yearChart breakYearChart, breakYears, breakYearsGroup, "Breakdown Year"

        pieChart quantityChart, quantities, quantities.group(), all
        pieChart qualityChart, qualities, qualities.group(), all
        pieChart extractionChart, extractionTypes, extractionTypes.group(), all
        pieChart statusChart, statuses, statusGroup, all, statusColor
        pieChart paymentChart, paymentTypes, paymentGroup, all
        pieChart installerChart, installers, installersGroup, all
        pieChart funderChart, funders, fundersGroup, all
        pieChart managementChart, managements, managementsGroup, all

        dc.dataCount(".dc-data-count").dimension(xfilter).group(all)
        makeDataTable("#dc-data-table", wards)

        dc.renderAll()

    regionsChoropleth = (chart, dim, group, json) ->
      chart
        .width(null)
        .height(null)
        .dimension(dim)
        .group(group)
        .colorDomain([0,100])
        .overlayGeoJson(json, "region", (d) -> d.properties.REGNAME)
        .title((d) -> d.key + ": " + d.value.percFun + " % functional")

    rowChart = (chart, dim, group) ->
      chart
        .width(null)
        .height(null)
        .margins({top: 10, left: 10, right: 10, bottom: 20})
        .group(group)
        .ordering((x) -> -x.value)
        .dimension(dim)
        .cap(10)
        .label((d) -> d.key)
        .title((d) -> d.key)
        .elasticX(true)
        .xAxis().ticks(4)

    bubbleChart = (chart, dim, group, colorAcc, keyAcc, valueAcc, radiusAcc, xlabel, ylabel) ->
      chart
        .width(null)
        .height(null)
        .transitionDuration(1500)
        .margins({top: 10, right: 20, bottom: 30, left: 40})
        .dimension(dim)
        .group(group)
        .colorAccessor(colorAcc)
        .keyAccessor(keyAcc)
        .valueAccessor(valueAcc)
        .radiusValueAccessor(radiusAcc)
        .maxBubbleRelativeSize(0.06)
        .x(d3.scale.linear().domain(d3.extent(group.all(),keyAcc)))
        .y(d3.scale.linear().domain(d3.extent(group.all(),valueAcc)))
        .r(d3.scale.linear().domain(d3.extent(group.all(),radiusAcc)))
        .elasticY(true)
        .elasticX(true)
        .yAxisPadding(0)
        .xAxisPadding(0)
        .renderHorizontalGridLines(true)
        .renderVerticalGridLines(true)
        .xAxisLabel(xlabel)
        .yAxisLabel(ylabel)
        .renderLabel(true)
        .label((p) -> p.key)
        .title((d) ->
          d.key +
            "\nAverage payment: " + valueAcc(d).toPrecision(4) +
            "\n% Functional: " + keyAcc(d).toPrecision(4) +
            "\nPopulation: " + radiusAcc(d))
        .renderTitle(true)
        .on("preRender", (chart) ->
          chart.rescale())
        .on("preRedraw", (chart) ->
          chart.rescale())

    removeEmptyGroups = (group) ->
      group2 =
        all: () ->
          group.all().filter((d) -> d.value.count > 0)

    statusBarChart = (chart, dim, group, gap) ->
      chart
        .width(null)
        .height(null)
        .margins({top: 20, left: 40, right: 20, bottom: 55})
        .group(group,"Functional")
        .dimension(dim)
        .ordering((d) -> -d.value.functional / d.value.count)
        .valueAccessor((p) -> p.value.functional)
        .stack(group, "Needs Repair", (d) -> d.value["needs repair"])
        .stack(group, "Not Functional", (d) -> d.value["not functional"])
        .x(d3.scale.ordinal())
        .xUnits(dc.units.ordinal)
        .colors(statusColor)
        .elasticY(true)
        .elasticX(true)
        .gap(gap || 10)
        .renderlet((chart) ->
          chart.selectAll("g.x text")
          .attr('dx', '-30')
          .attr('transform', "rotate(-65)"))
        .label((d) -> d.key)
        .title((d) ->
          d.key +
            "\nFunctional: " + d.value.functional +
            "\nNeeds repair: " + d.value["needs repair"] +
            "\nNot functional: " + d.value["not functional"])
        .legend(dc.legend().horizontal(true).itemWidth(85).x(50).y(0))
        .on("preRender", (chart) ->
          chart.rescale())
        .on("preRedraw", (chart) ->
          chart.rescale())

    pieChart = (chart, dim, group,all, colorScale) ->
      chart
        .width(null)
        .height(null)
        .innerRadius(30)
        .dimension(dim)
        .group(group)
        .transitionDuration(1000)
        .label((d) ->
          if (chart.hasFilter() && !chart.hasFilter(d.key))
            d.key + "(0%)"
          else
            d.key + " (" + Math.floor(d.value / all.value() * 100) + "%)")
        .title((d) ->
          d.key + " (" + Math.floor(d.value / all.value() * 100) + "%)")

      if colorScale then chart.colors(colorScale)

    yearChart = (chart, dim, group, xlabel) ->
      chart
        .width(null)
        .height(null)
        .margins({top: 20, left: 40, right: 20, bottom: 22})
        .group(group)
        .dimension(dim)
        .centerBar(true)
        .ordering((d) -> d.key)
        .valueAccessor((p) -> p.value.functional)
        .stack(group, "Needs Repair", (d) -> d.value["needs repair"])
        .stack(group, "Not Functional", (d) -> d.value["not functional"])
        .colors(statusColor)
        .elasticY(true)
        .elasticX(true)
        .gap(1)
        .x(d3.time.scale().domain([new Date(YEAR_ZERO, 0, 1), new Date(2014, 12, 31)]))
        .xUnits(d3.time.years)
        .on("preRender", (chart) ->
          chart.rescale())
        .on("preRedraw", (chart) ->
          chart.rescale())
        .yAxis().ticks(4)

    reloadTable = (datatable,dim) ->
      alldata = dim.top(Infinity)
      datatable.fnClearTable()
      datatable.fnAddData(alldata)
      datatable.fnDraw()

    makeDataTable = (selector, dim) ->
      exists = $.fn.DataTable.fnIsDataTable($(selector))

      if exists
        datatable = $(selector).dataTable()
        reloadTable(datatable,dim)
      else
        cols = $scope.fields.map((x) ->
          if x.endsWith("_year")
            mData: x
            sDefaultContent: ""
            mRender: (obj) ->
              y = obj.getFullYear()
              if y == YEAR_ZERO then "unknown" else y
          else
            {mData: x, sDefaultContent: ""})

        datatable = $(selector).dataTable
          bPaginate: true,
          pagingType: "full",
          iDisplayLength: 25,
          scrollX: true,
          scrollY: 500,
          scrollCollapse: true,
          bSort: true,
          bDeferRender: true,
          aaData: dim.top(Infinity),
          bDestroy: true,
          aoColumns: cols

      dc.chartRegistry.list().forEach (chart) ->
        chart.on "filtered", () ->
          dc.events.trigger () ->
            reloadTable(datatable,dim)

    reduceStatus = (group) ->
      res = group.reduce(\
        ((p, v) ->
          ++p.count
          p[v.status_group] += 1
          return p),
        ((p, v) ->
          --p.count
          p[v.status_group] -= 1
          return p),
        (() ->
          count: 0, functional: 0, "not functional": 0, "needs repair": 0))
      res

    reduceCostStatus = (group) ->
      isFunc = (x) -> x.status_group == "functional"
      res = group.reduce(\
        ((p, v) ->
          ++p.count
          p.total += v.amount_tsh
          p.pop_served_fun += if isFunc(v) then v.population else 0
          p.numFun += if isFunc(v) then 1 else 0
          p.avgCost = p.total / p.count
          p.percFun = p.numFun / p.count * 100
          p),
        ((p, v) ->
          --p.count
          p.total -= v.amount_tsh
          p.pop_served_fun -= if isFunc(v) then v.population else 0
          p.numFun -= if isFunc(v) then 1 else 0
          p.avgCost = (p.count) ? p.total / p.count * 1 : 0
          p.percFun = (p.count) ? p.numFun / p.count * 100 : 0
          p),
        (() ->
          count: 0, total: 0, pop_served_fun: 0, pop: 0, popReach: 0, percFun: 0, numFun: 0, avgCost: 0))

      res.all().forEach((d) ->
        # Lookup the population of the ward
        pop = popData.lookup(null,null,d.key)
        if pop > 0
          d.value.pop = pop
          d.value.popReach = d.value.pop_served_fun / d.value.pop * 100)

      res

    reduceAvg = (group, fieldAcc) ->
      res = group.reduce(\
        ((p, v) ->
          ++p.count
          p.total += fieldAcc(v)
          p.avg = p.total / p.count
          p),
        ((p, v) ->
          --p.count
          p.total -= fieldAcc(v)
          p.avg = p.total / p.count
          p),
        (() -> count: 0, total: 0))
      res

String.prototype.endsWith = (suffix) ->
  this.indexOf(suffix, this.length - suffix.length) != -1
