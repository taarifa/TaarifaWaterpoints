//to prevent creating overcrowded plots
var minColWidth = 25;

//all this code should die slowly and painfully
var $scope;
var statusColor = d3.scale.ordinal()
    .domain(["Functional","Not functional"])
    .range(["#0a871f","#d50000"]);

var swstatus;

var gettext = null;


function updatePlots(angularScope, region, district, ward, groupfield) {
  $scope = angularScope;
  gettext = $scope.translate;

  swstatus = {
    "Functional": gettext("Functional"),
    "Not functional": gettext("Not functional")
  };

  groupfield = groupfield || "region";
  var url = "/api/waterpoints/stats_by/" + groupfield;

  var filterFields = {"region":region, "district":district, "ward":ward};
  var filters = [];

  _.keys(filterFields).forEach(function(x){
    if(filterFields[x]) filters.push(x + "=" + filterFields[x]);
  });

  var filter = filters.join("&");
  var url3 = url; 
  var url2 = "/api/waterpoints/stats_by/construction_year";
  if(filter) {
      url += "?" + filter;
      url2 += "?" + filter;
      url3 += "?water_payment=Pay per bucket&" + filter;
  }else{
   url3 += "?water_payment=Pay per bucket";
  }
  var comparator = function(a, b) {
    var af = _.find(a.waterpoints, function(x) {
      return x.status == "Functional";
    });
    var bf = _.find(b.waterpoints, function(x) {
      return x.status == "Functional";
    });

    if (!af) {
      af = {
        status: "Functional",
        count: 0
      };
      a.waterpoints.push(af);
    }
    if (!bf) {
      bf = {
        status: "Functional",
        count: 0
      };
      b.waterpoints.push(bf);
    }

    var aperc = af.count / a.count;
    var bperc = bf.count / b.count;

    //if percentage is equal sort by count
    if(Math.abs(aperc - bperc) < 0.001){
        return bf.count - a.count;
    }else{
        return bperc - aperc;
    }
  }

  kpiCoverage("#kpiCoverage");
  //kpiStruct("#kpiStruct");

  d3.json(url2, function(error, wpdata) {
    data = wpdata;
    //data = [].concat.apply([], _.pluck(wpdata,"waterpoints"));

    data.forEach(function(x){
        if(!x.construction_year){
            x.cyear = 1900;
        }else{
            x.cyear = +x.construction_year.substring(12,16);
        }
    });
    data.sort(function(a, b) { return a.cyear - b.cyear; });

    plotCyearSummary("#cyearSummary", data, "cyear");
  });

  d3.json(url, function(error, data) {
    //sort by % functional waterpoints
    data.sort(comparator);

    plotStatusSummary("#statusSummary", data, groupfield);
  });

  d3.json(url3, function(error, data) {
    //sort by % functional waterpoints
    data.sort(comparator);

    plotSpendSummary("#spendSummary", data, groupfield);
    plotSpendImpact("#spendImpact", data, groupfield);
  });
}

function toTitleCase(str){
    return str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
}

function barSelected(groupField,d){
        if(_.contains(["region","district","lga_name","ward"],groupField)){
            $scope.$apply(function(){
                if(!$scope.params) $scope.params = {};

                /*var gforder = {"region": "district",
                               "district": "lga_name",
                               "lga_name": "ward",
                               "ward": "region"};
*/
                var gforder = {"region": "district",
                               "district":"ward",
                               "ward": "region"};

                var newgf = gforder[groupField];

                $scope.group = newgf;
                if(newgf != "region"){
                    var pname = (groupField == "lga_name") ? "lga" : groupField;
                    $scope.params[pname] = d[groupField];
                    $scope.getStatus(groupField);
                }else{
                    $scope.resetFilter();
                }
            });
        }
}

function linspace(interval,n){
    var start = interval[0];
    var stop = interval[1];
    var delta = Math.floor((stop-start) / (n-2));
    var nums = [start];
    var cur = start;
    while(cur < stop){
        cur += delta;
        nums.push(cur);
    }
    nums.push(stop);
    return nums;
}

/*
 * Stacked bar chart summarizing the status (functional/non functional)
 * of all the waterpoints by the given group field
 */
function plotStatusSummary(selector, data, groupField) {

  data.forEach(function(group) {
    var y0 = 0;
    //status type is not always in the same order due to mongo, sort here
    group.waterpoints = _.sortBy(group.waterpoints, "status");
    group.waterpoints.forEach(function(x) {
      x.y0 = y0;
      x.y1 = (y0 += x.count);
    });
  });
  //data.sort(function(a, b) { return b.count - a.count; });

  // Compensate for well margins (20px)
  var h = d3.select(selector).style('height').replace('px', '') - 40;
  var w = d3.select(selector).style('width').replace('px', '') - 40;

  var margin = {
      top: 20,
      right: 20,
      bottom: 90,
      left: 70
    },
    width = w - margin.left - margin.right,
    height = h - margin.top - margin.bottom;

  //to prevent creating overcrowded plots
  data = data.slice(0,Math.floor(width/minColWidth));

  var x = d3.scale.ordinal()
    .rangeRoundBands([0, width], .1);

  var y = d3.scale.linear()
    .rangeRound([height, 0]);

  x.domain(_.pluck(data, groupField));
  y.domain([0, d3.max(data, function(d) {
    return d.count;
  })]);


  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    .tickFormat(function(d){return shorten(d); });

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");


  //create the svg if it does not already exist
  svg = d3.select(selector + " svg g");
  if (!svg[0][0]) {
    svg = d3.select(selector).append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      //transform within the margins
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")");

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", -70)
      .attr("dy", ".71em")
      .style("text-anchor", "end");
      //.text("Number of Waterpoints");
  }

  var tip = d3.tip().attr('class', 'd3-tip').html(function(d) {
      return d[groupField];
  });
  svg.call(tip);

  //bind the data to a group
  var state = svg.selectAll(".group")
    .data(data, function(d) {
      return groupField + "_" + d[groupField] + "_" + d.count;
      //return d[groupField];
    });

  //bind to each rect within the group
  var rects = state.selectAll("rect")
    .data(function(d) {
      return d.waterpoints;
    }, function(d) {
      return d.status + "_" + d.count;
      //return d.status;
    });

  //new groups
  var statesEnter = state.enter()
    .append("g")
    .attr("class", "group")
    .attr("transform", function(d) {
      return "translate(" + x(d[groupField]) + ",0)";
    })
    .on('dblclick', function(d,i){
        tip.hide(d);
        barSelected(groupField,d);
    })
    .on('mouseover', tip.show)
    .on('mouseout', tip.hide);

  //new rects in new groups
  var rectsEnter = statesEnter.selectAll("rect")
    .data(function(d) {
      return d.waterpoints;
    }, function(d) {
      return d.status + "_" + d.count;
    })

  //remove old rects
  rects.exit()
    .transition()
    .duration(1000)
    .attr("y", y(0))
    .attr("height", 0)
    .call(tip.hide)
    .remove();

  //remove old groups
  state.exit()
    .transition()
    .duration(1000)
    .style("opacity", 0)
    .remove();

  //update existing rects
  rects.attr("width", x.rangeBand())
    .style("fill", function(d) {
      return statusColor(d.status);
    })
    .transition()
    .duration(1000)
    .attr("width", x.rangeBand())
    .attr("y", function(d) {
      return y(d.y1);
    })
    .attr("height", function(d) {
      return y(d.y0) - y(d.y1);
    });

  //add new rects
  rectsEnter.enter().append("rect")
    .attr("width", x.rangeBand())
    .style("fill", function(d) {
      return statusColor(d.status);
    })
    .attr("y", y(0))
    .attr("height", 0)
    .transition()
    .duration(1000)
    .attr("y", function(d) {
      return y(d.y1);
    })
    .attr("height", function(d) {
      return y(d.y0) - y(d.y1);
    });

  //Update the axes
  svg.select("g.x.axis").transition().duration(1000).call(xAxis)
    .selectAll("text")
    .style("text-anchor", "end")
    .attr("dx", "-.8em")
    .attr("dy", ".15em")
    .attr("transform", function(d) {
      return "rotate(-65)"
    });

  svg.select("g.y.axis").transition().call(yAxis);

  //add a legend
  svg.selectAll(".legend").remove();

  var legend = svg.selectAll(".legend")
    .data(statusColor.domain());

  legend.enter().append("g")
    .attr("class", "legend")
    .attr("transform", function(d, i) {
      return "translate(0," + i * 20 + ")";
    });

  legend.append("rect")
    .attr("x", width - 18)
    .attr("width", 18)
    .attr("height", 18)
    .style("fill", function(d){return statusColor(d);});

  legend.append("text")
    .attr("x", width - 24)
    .attr("y", 9)
    .attr("dy", ".35em")
    .style("text-anchor", "end")
    .text(function(d) {
      return swstatus[d];
    });
}


function plotSpendSummary(selector, data, groupField) {

  data.sort(function(a, b) { return b.avgBucketCost - a.avgBucketCost; });

  // Compensate for well margins (20px)
  var h = d3.select(selector).style('height').replace('px', '') - 40;
  var w = d3.select(selector).style('width').replace('px', '') - 40;

  var margin = {
      top: 20,
      right: 20,
      bottom: 90,
      left: 70
    },
    width = w - margin.left - margin.right,
    height = h - margin.top - margin.bottom;

  //to prevent creating overcrowded plots
  data = data.slice(0,Math.floor(width/minColWidth));

  var x = d3.scale.ordinal()
    .rangeRoundBands([0, width], .1);

  var y = d3.scale.linear()
    .rangeRound([height, 0]);

  x.domain(_.pluck(data, groupField));
  y.domain([0, d3.max(data, function(d) {
    return d.avgBucketCost;
  })]);

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    .tickFormat(function(d){return shorten(d); });


  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

  var color = d3.scale.ordinal()
    .domain(["#284fc7"]);

  var colval ="#284fc7";

  svg = d3.select(selector + " svg g");
  if (!svg[0][0]) {
    svg = d3.select(selector).append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
    //transform within the margins
    .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")");

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", -70)
      .attr("dy", ".71em")
      .style("text-anchor", "end");
      //.text("Average Bucket Price");
  }

  var tip = d3.tip().attr('class', 'd3-tip').html(function(d) {
      return groupField + "_" + d[groupField];
  });
  svg.call(tip);

  var rects = svg.selectAll("rect")
    .data(data, function(d) {
      return d[groupField];
    });

  rects
    //.append("rect")
    .style("fill", function(d) {
      //return color(d[groupField]);
        return colval;
    })
    .transition()
    .attr("width", x.rangeBand())
    .attr("x", function(d) {
      return x(d[groupField]);
    })
    .duration(1000)
    .attr("y", function(d) {
      return y(d.avgBucketCost);
    })
    .attr("height", function(d) {
      return height - y(d.avgBucketCost);
    });

  rects.enter()
    .append("rect")
    .style("fill", function(d) {
      //return color(d[groupField]);
        return colval;
    })
    .attr("width", x.rangeBand())
    .attr("x", function(d) {
      return x(d[groupField]);
    })
    .attr("y", y(0))
    .attr("height", 0)
    .on('mouseover', tip.show)
    .on('mouseout', tip.hide)
    .on('dblclick', function(d,i){
        tip.hide(d);
        barSelected(groupField,d);
    })
    .transition()
    .duration(1000)
    .attr("y", function(d) {
      return y(d.avgBucketCost);
    })
    .attr("height", function(d) {
      return height - y(d.avgBucketCost);
    });

  rects.exit()
    .transition()
    .duration(1000)
    .attr("y", y(0))
    .attr("height", 0)
    .style("opacity", 0)
    .remove();

  //Update the axes
  svg.select("g.x.axis").transition().duration(1000).call(xAxis)
    .selectAll("text")
    .style("text-anchor", "end")
    .attr("dx", "-.8em")
    .attr("dy", ".15em")
    .attr("transform", function(d) {
      return "rotate(-65)"
    });

  svg.select("g.y.axis").transition().call(yAxis);
}

function plotSpendImpact(selector, wpdata, groupField) {

  //TODO: more made up data
  data = [];
  wpdata.forEach(function(x) {
    var functional = _.find(x.waterpoints, function(x) {
      return x.status == "Functional";
    });
    var d = {
      functional: functional.count / x.count * 100,
      population: d3.sum(_.pluck(x.waterpoints, "population")),
      spend: x.avgBucketCost //10 + (Math.random() * 10000 / x.count)
    };
    d[groupField] = x[groupField];
    data.push(d);
  });

  // Compensate for well margins (20px)
  var h = d3.select(selector).style('height').replace('px', '') - 40;
  var w = d3.select(selector).style('width').replace('px', '') - 40;

  var margin = {
      top: 20,
      right: 20,
      bottom: 20,
      left: 40
    },
    width = w - margin.left - margin.right,
    height = h - margin.top - margin.bottom;

  var x = d3.scale.linear()
    .range([0, width])
    .domain(d3.extent(_.pluck(data, "spend"))).nice();

  var y = d3.scale.linear()
    .range([height, 0])
    .domain(d3.extent(_.pluck(data, "functional")));

  var popScale = d3.scale.sqrt()
    .range([5, 15])
    .domain(d3.extent(_.pluck(data, "population")));

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    .tickFormat(function(d){return shorten(d); });

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

  var color = d3.scale.ordinal()
    .domain(["#284fc7"]);
    var colval="#284fc7";
    

  svg = d3.select(selector + " svg g");
  if (!svg[0][0]) {
    svg = d3.select(selector).append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
    //transform within the margins
    .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis)
      .append("text")
      .attr("class", "label")
      .attr("x", width)
      .attr("y", -6)
      .style("text-anchor", "end")
      .text(gettext("Average Price Per Bucket (TSH)"));

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("class", "label")
      .attr("transform", "rotate(-90)")
      .attr("y", -40)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text(gettext("% Functional"));
  }


  //TODO: use d3.tip
  //TODO: gets added each time
  var tooltip = d3.select("body").append("div")
    .attr("class", "tooltip")
    .style("opacity", 0);

  var dots = svg.selectAll(".dot")
    .data(data, function(d) {
      return d[groupField]
    });

  dots
    .transition()
    .duration(1000)
    .attr("cx", function(d) {
      return x(d.spend);
    })
    .attr("cy", function(d) {
      return y(d.functional);
    })
    .attr("r", function(d) {
      return popScale(d.population);
    });

  dots.enter()
    .append("circle")
    .attr("class", "dot")
    .style("stroke-width","0")
    .attr("cx", function(d) {
      return x(d.spend);
    })
    .attr("cy", function(d) {
      return y(d.functional);
    })
    .style("fill", function(d) {
      //return color(d[groupField]);
        return colval;
    })
    .attr("r", 0)
    .on('dblclick', function(d,i){
        barSelected(groupField,d);
    })
    .style("opacity",0.6)
    .transition()
    .duration(1000)
    .attr("r", function(d) {
      return popScale(d.population);
    });

  dots.exit()
    .transition()
    .duration(1000)
    .attr("r", 0)
    .remove();
  
  svg.select("g.x.axis").transition().duration(1000).call(xAxis);
  svg.select("g.y.axis").transition().duration(1000).call(yAxis);


  dots.on("mouseover", function(d) {

     var circle = d3.select(this);
circle.transition().duration(500)
.attr("r", circle.attr("r") * 1 + 5 );
 
    tooltip.transition()
      .duration(100)
      .style("opacity", .9);
    tooltip.html("<b>" + d[groupField] + "</b>" + "<br/><em>" + gettext("Avg Bucket Price") + ":</em> " + d.spend.toPrecision(3) + " TSH<br/><em>" + gettext("Functional")+ ":</em> " + d.functional.toPrecision(3) + " %" + "<br/><em>" 
                 + gettext("Population served") + ":</em> " + d.population)
      .style("left", (d3.event.pageX + 15) + "px")
      .style("top", (d3.event.pageY - 28) + "px");
  })
    .on("mouseout", function(d) {
     var circle = d3.select(this);
circle.transition().duration(500)
.attr("r", circle.attr("r") * 1 - 5 );


 tooltip.transition()
        .duration(500)
        .style("opacity", 0);
    });
}

function shorten(s, maxlen) {
  if (!s) return s;
  if (!maxlen) maxlen = 13;
  return (s.length > maxlen) ? s.slice(0, maxlen - 3) + "..." : s;
}

function kpiCoverage(selector){
  var h = d3.select(selector).style('height').replace('px', '') - 40;
  var w = d3.select(selector).style('width').replace('px', '') - 40;

var margin = {top: 20, right: 60, bottom: 90, left: 50},
    width = w - margin.left - margin.right,
    height = h - margin.top - margin.bottom;

var parseDate = d3.time.format("%d-%b-%y").parse;

var x = d3.time.scale()
    .range([0, width]);

var y = d3.scale.linear()
    .domain([0,100])
    .range([height, 0]);

var y1 = d3.scale.linear().range([height, 0]);

var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    //.ticks(d3.time.years)
    .tickFormat(d3.time.format("%d-%b-%y"));

var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

var yAxis1 = d3.svg.axis()
    .scale(y1)
    .orient("right");

var line = d3.svg.line()
    .x(function(d) { return x(d.date); })
    .y(function(d) { return y(d.coverage_percent); });

var line1 = d3.svg.line()
    .x(function(d) { return x(d.date); })
    .y(function(d) { return y1(d.new_infr_projects); });


d3.select(selector + " svg").remove();

var svg = d3.select(selector).append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
  .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

d3.csv("kpis.csv", function(error, data) {
  data.forEach(function(d) {
    d.date = parseDate(d.date);
    d.coverage_percent = +d.coverage_percent;
    d.new_infr_projects = +d.new_infr_projects;
  });

  xAxis.tickValues(_.pluck(data,"date"));

  x.domain(d3.extent(data, function(d) { return d.date; }));
  y.domain(d3.extent(data, function(d) { return d.coverage_percent; }));
  y1.domain(d3.extent(data, function(d) { return d.new_infr_projects; }));

  svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis)
          .selectAll("text")
    .style("text-anchor", "end")
    .attr("dx", "-.8em")
    .attr("dy", ".15em")
    .attr("transform", function(d) {
      return "rotate(-65)"
    });

    var blue="#284fc7";
    var red="#0a871f";
  svg.append("g")
      .attr("class", "y axis")
      .style("fill", blue) 
      .call(yAxis)
    .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text(gettext("Coverage %"));

  svg.append("g")
      .attr("class", "y axis")
      .style("fill", red)
      .attr("transform", "translate(" + width + " ,0)")
      .call(yAxis1)
    .append("text")
      .attr("transform", "rotate(-90)")
      .attr("x", -10)
      .attr("y", -16)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text(gettext("New Infrastructure Projects"));

  svg.append("path")
      .datum(data)
      .attr("class", "line")
      .style("stroke", blue)
      .attr("d", line);
  svg.append("path")
      .datum(data)
      .attr("class", "line")
      .style("stroke", red)
      .attr("d", line1);
});

}


function plotCyearSummary(selector, data, groupField) {

  // Compensate for well margins (20px)
  var h = d3.select(selector).style('height').replace('px', '') - 40;
  var w = d3.select(selector).style('width').replace('px', '') - 40;

  var margin = {
      top: 20,
      right: 20,
      bottom: 90,
      left: 70
    },
    width = w - margin.left - margin.right,
    height = h - margin.top - margin.bottom;

  //to prevent creating overcrowded plots
  minColWidth = 10
  data = data.slice(0,Math.floor(width/minColWidth));

  var x = d3.scale.ordinal()
    .rangeRoundBands([0, width], .1);

  var y = d3.scale.linear()
    .rangeRound([height, 0]);

  x.domain(_.pluck(data, groupField));


  y.domain(d3.extent(data, function(d) {
    return d.count;
  }));

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    .tickFormat(function(d){return shorten(d); });


  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

  var color = d3.scale.ordinal()
    .domain(["#284fc7"]);
    var colval="#284fc7";

  svg = d3.select(selector + " svg g");
  if (!svg[0][0]) {
    svg = d3.select(selector).append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
    //transform within the margins
    .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")");

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", -70)
      .attr("dy", ".71em")
      .style("text-anchor", "end");
      //.text("Average Bucket Price");
  }

  var tip = d3.tip().attr('class', 'd3-tip').html(function(d) {
      return d[groupField];
  });
  svg.call(tip);

  var rects = svg.selectAll("rect")
    .data(data, function(d) {
      return d.cyear;
        //return [groupField,d[groupField],d.cyear].join("_");
    });

  rects
    .style("fill", function(d) {
      return colval;//return color(d[groupField]);
    })
    .transition()
    .duration(1000)
    .attr("width", x.rangeBand())
    .attr("x", function(d) {
      return x(d[groupField]);
    })
    .attr("y", function(d) {
      return y(d.count);
    })
    .attr("height", function(d) {
      return height - y(d.count);
    });

  rects.enter()
    .append("rect")
    .style("fill", function(d) {
      return colval;//return color(d[groupField]);
    })
    .attr("width", x.rangeBand())
    .attr("x", function(d) {
      return x(d[groupField]);
    })
    .attr("y", y(0))
    .attr("height", 0)
    .on('mouseover', tip.show)
    .on('mouseout', tip.hide)
    .on('dblclick', function(d,i){
        tip.hide(d);
        barSelected(groupField,d);
    })
    .transition()
    .duration(1000)
    .attr("y", function(d) {
      return y(d.count);
    })
    .attr("height", function(d) {
      return height - y(d.count);
    });

  rects.exit()
    .transition()
    .duration(1000)
    .style("opacity", 0)
    .remove();

  //Update the axes
  svg.select("g.x.axis").transition().duration(1000).call(xAxis)
    .selectAll("text")
    .style("text-anchor", "end")
    .attr("dx", "-.8em")
    .attr("dy", ".15em")
    .attr("transform", function(d) {
      return "rotate(-65)"
    });

  svg.select("g.y.axis").transition().call(yAxis);
}

var executeOnce = (function (fn, delay) {
  var executed = false;
  return function (/* args */) {
    var args = arguments;
    if (!executed) {
      setTimeout(function () {
        fn.apply(null, args); // preserve arguments
      }, delay);
      executed = true;
    }
  };
});
