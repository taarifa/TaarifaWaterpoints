//to prevent creating overcrowded plots
var minColWidth = 20;
//FIXME: hardcoded list of possible status fields
var statusColor = d3.scale.ordinal()
    .domain(["functional","needs repair", "not functional"])
    .range(["#0a871f","orange","#d50000"]);

function isFunctional(s) {
    return s.status == "functional";
}

function getDimensions(selector, wMargin, hMargin){
  // Compensate for well margins (20px)
  var pn = d3.select(selector).node().parentNode;

  //var h = d3.select(selector).style('height').replace('px', '') - 40;
  //var w = d3.select(selector).style('width').replace('px', '') - 40;
  var h = d3.select(pn).style('height').replace('px', '') - (hMargin || 60);
  var w = d3.select(pn).style('width').replace('px', '') - (wMargin || 40);

  return {h: h, w: w};
}

function createTip(getter) {
  var tip = d3.tip().style("z-index",100).attr('class', 'd3-tip').html(getter);
  return tip;
}

function closeOpenTips() {
  $('.d3-tip').filter(function(){
    var $this = $(this);
    return $this.css('opacity') == 1;
  }).hide();
}

/*
 * Stacked bar chart summarizing the status (functional/non functional)
 * of all the waterpoints by the given group field
 */
function plotStatusSummary(selector, data, groupField, dblClickHandler, translate, selectedStatus) {
  //rename as gettext so string extraction will work
  gettext = translate;

  data.forEach(function(group) {
    var y0 = 0;
    //status type is not always in the same order due to mongo, sort here
    group.waterpoints = _.sortBy(group.waterpoints, "status");
    group.waterpoints.forEach(function(x) {
      //only calculate the rectangle offsets for the requested status
      if(selectedStatus == "all" || x.status == selectedStatus) {
        x.y0 = y0;
        x.y1 = (y0 += x.count);
      }
    });
  });
  //data.sort(function(a, b) { return b.count - a.count; });

  var dims = getDimensions(selector);
  var h = dims.h, w = dims.w;

  var margin = {
      top: 10,
      right: 20,
      bottom: 110,
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
  var svg = d3.select(selector + " svg");

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
      .attr("class", "axislabel")
      .attr("transform", "rotate(-90)")
      .attr("y", -70)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("");
  } else {
    //Note width/height may have changed
    svg.attr("width", width + margin.left + margin.right)
       .attr("height", height + margin.top + margin.bottom);
    svg = svg.select('g');
  }

  var tip = createTip(function(d) {
      s = d[groupField];

      d.waterpoints.map(function(x){return _.pick(x,["status","count"]);})
        .forEach(function(x){
          s += '<br /><span style="color:' + statusColor(x.status) + '">' + x.status + ': ' + x.count + '</span>';})

      return s
  });

  svg.call(tip);

  var filterSelected = function(waterpoints) {
    var wp = waterpoints.filter(function(x){
      if(selectedStatus == "all"){
        return true;
      }else{
        return x.status == selectedStatus;
      }
    });

    return wp;
  }

  //bind the data to a group
  var state = svg.selectAll(".group")
    .data(data, function(d) {
        return d[groupField] + "_" + selectedStatus;
        //return groupField + "_" + d[groupField] + "_" + d.count;
    });

  //bind to each rect within the group
  var rects = state.selectAll("rect")
    .data(function(d) {
      //only keep the waterpoint groups with the status we want
      return filterSelected(d.waterpoints);
    }, function(d) {
        return d.status;
        //return d.status + "_" + d.count;
    });

  //new groups
  var statesEnter = state.enter()
    .append("g")
    .attr("class", "group")
    .attr("transform", function(d) {
      return "translate(" + x(d[groupField]) + ",0)";
    })
    .on('dblclick', function(d,i){
        tip.hide(d,i);
        dblClickHandler(d);
    })
    .on('mouseover', tip.show)
    .on('mouseout', tip.hide);

  //new rects in new groups
  var rectsEnter = statesEnter.selectAll("rect")
    .data(function(d) {
      //only keep the waterpoint groups with the status we want
      return filterSelected(d.waterpoints);
    }, function(d) {
        return d.status;
        //return d.status + "_" + d.count;
    })

  //update existing groups
  state.attr("transform", function(d) {
      return "translate(" + x(d[groupField]) + ",0)";
    });

  //update existing rects
  rects
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

  //remove old rects
  rects.exit()
    .transition()
    .duration(1000)
    .attr("y", y(0))
    .attr("height", 0)
    .call(tip.hide);
  //  .remove();

  //remove old groups
  state.exit()
    .on('mouseover', null)
    .on('mouseout', null)
    .transition()
    .duration(1000)
    .style("opacity", 0)
    .remove();

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
    .attr("transform", "translate(0," + height + ")")
    .selectAll("text")
    .style("text-anchor", "end")
    .attr("dx", "-.8em")
    .attr("dy", ".15em")
    .attr("transform", function(d) {
      return "rotate(-65)"
    });

  svg.select("g.y.axis text.axislabel").text(gettext("Number of Waterpoints"));
  svg.select("g.y.axis").transition().call(yAxis);
}

function leaderChart(selector, data, groupField, getter) {

  var dims = getDimensions(selector);
  var h = dims.h, w = dims.w;

  var margin = {
      top: 10,
      right: 20,
      bottom: 20,
      left: 20
    },
    width = w - margin.left - margin.right,
    height = h - margin.top - margin.bottom;

  //to prevent creating overcrowded plots
  data = data.slice(0,Math.floor(height/minColWidth));

  var x = d3.scale.linear()
    .domain([0, 100])
    .rangeRound([0, width]);

  var y = d3.scale.ordinal()
    .domain(_.pluck(data, groupField))
    .rangeRoundBands([0,height], .1);

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left")
    .tickFormat("");

  var color = d3.scale.category20();

  svg = d3.select(selector + " svg");
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
  } else {
    //Note width/height may have changed
    svg.attr("width", width + margin.left + margin.right)
       .attr("height", height + margin.top + margin.bottom);
    svg = svg.select('g');
  }

  var tip = createTip(function(d) {
      s = d[groupField] + ": " + getter(d).toPrecision(4) + " %";
      return s;
  });

  svg.call(tip);

  var rects = svg.selectAll("rect")
    .data(data, function(d) {
      return d[groupField];
    });

  var labels = svg.selectAll(".hor-bar-label")
    .data(data, function(d) {
      return d[groupField];
    });

  rects
    .transition()
    .duration(1000)
    .attr("height", y.rangeBand())
    .attr("y", function(d) {
      return y(d[groupField]);
    })
    .attr("x", function(d) {
      return x(0);
    })
    .attr("width", function(d) {
      return x(getter(d));
    });

  labels
    .transition()
    .duration(1000)
    .attr("y", function(d) {
      return y(d[groupField]) + y.rangeBand(d)/2;
    })
    .attr("x", function(d) {
      return x(0) + 5;
    })
    .text(function(d){
      return d[groupField];
    });

  rects.enter()
    .append("rect")
    .attr("class","hor-bar")
    .attr("height", y.rangeBand())
    .attr("y", function(d) {
      return y(d[groupField]);
    })
    .attr("x", x(0))
    .attr("width", 0)
    .on('mouseover', tip.show)
    .on('mouseout', tip.hide)
    .transition()
    .duration(1000)
    .attr("width", function(d) {
      return x(getter(d));
    });

  labels.enter()
    .append("text")
    .attr("class","hor-bar-label")
    .text(function(d){
      return d[groupField];
    })
    .style("opacity", 0)
    .attr("y", function(d) {
      return y(d[groupField]) + y.rangeBand(d)/2;
    })
    .attr("dy", ".36em")
    .attr("x", function(d) {
      return x(0) + 5;
    })
    .transition()
    .duration(1000)
    .style("opacity", 1);

  rects.exit()
    .transition()
    .duration(1000)
    .attr("width",0)
    .style("opacity", 0)
    .remove();

  labels.exit()
    .transition()
    .duration(1000)
    .style("opacity", 0)
    .remove();

  //Update the axes
  svg.select("g.x.axis").transition().duration(1000).call(xAxis)
    .attr("transform", "translate(0," + height + ")");

  svg.select("g.y.axis").transition().call(yAxis);

}

function plotSpendSummary(selector, data, groupField) {

  //TODO: need real data
  data.forEach(function(x) {
    x.spend = 10+(Math.random() * 10000 / x.count);
  });

  //data.sort(function(a, b) { return a.spend - b.spend; });

  var dims = getDimensions(selector);
  var h = dims.h, w = dims.w;

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
    return d.spend;
  })]);

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    .tickFormat(function(d){return shorten(d); });

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

  var color = d3.scale.category20();

  svg = d3.select(selector + " svg");
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
      .style("text-anchor", "end")
      .text("Spend per Waterpoint ($)");
  } else {
    //Note width/height may have changed
    svg.attr("width", width + margin.left + margin.right)
       .attr("height", height + margin.top + margin.bottom);
    svg = svg.select('g');
  }

  var tip = d3.tip().attr('class', 'd3-tip').html(function(d) {
      return d[groupField];
  });

  svg.call(tip);

  var rects = svg.selectAll("rect")
    .data(data, function(d) {
      return d[groupField];
    });

  rects
    .style("fill", function(d) {
      return color(d[groupField]);
    })
    .transition()
    .duration(1000)
    .attr("width", x.rangeBand())
    .attr("x", function(d) {
      return x(d[groupField]);
    })
    .attr("y", function(d) {
      return y(d.spend);
    })
    .attr("height", function(d) {
      return height - y(d.spend);
    });

  rects.enter()
    .append("rect")
    .style("fill", function(d) {
      return color(d[groupField]);
    })
    .attr("width", x.rangeBand())
    .attr("x", function(d) {
      return x(d[groupField]);
    })
    .attr("y", y(0))
    .attr("height", 0)
    .on('mouseover', tip.show)
    .on('mouseout', tip.hide)
    .transition()
    .duration(1000)
    .attr("y", function(d) {
      return y(d.spend);
    })
    .attr("height", function(d) {
      return height - y(d.spend);
    });

  rects.exit()
    .transition()
    .duration(1000)
    .attr("y",y(0))
    .attr("height",0)
    .style("opacity", 0)
    .remove();

  //Update the axes
  svg.select("g.x.axis").transition().duration(1000).call(xAxis)
    .attr("transform", "translate(0," + height + ")")
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
    var functional = _.find(x.waterpoints, isFunctional);
    var d = {
      functional: functional.count / x.count * 100,
      pop_served: d3.sum(_.pluck(x.waterpoints, "pop_served")),
      spend: 10 + (Math.random() * 10000 / x.count)
    };
    d[groupField] = x[groupField];
    data.push(d);
  });

  var dims = getDimensions(selector);
  var h = dims.h, w = dims.w;

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
    .domain(d3.extent(_.pluck(data, "spend")));

  var y = d3.scale.linear()
    .range([height, 0])
    .domain(d3.extent(_.pluck(data, "functional")));

  var popScale = d3.scale.sqrt()
    .range([5, 15])
    .domain(d3.extent(_.pluck(data, "pop_served")));

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    .tickFormat(function(d){return shorten(d); });

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

  var color = d3.scale.category20();

  svg = d3.select(selector + " svg");
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
      .text("Spend per Waterpoint ($)");

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("class", "label")
      .attr("transform", "rotate(-90)")
      .attr("y", -40)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("% Functional");
  } else {
    //Note width/height may have changed
    svg.attr("width", width + margin.left + margin.right)
       .attr("height", height + margin.top + margin.bottom);
    svg = svg.select('g');
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
      return popScale(d.pop_served);
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
      return color(d[groupField]);
    })
    .attr("r", 0)
    .style("opacity",0.6)
    .transition()
    .duration(1000)
    .attr("r", function(d) {
      return popScale(d.pop_served);
    });

  dots.exit()
    .transition()
    .duration(1000)
    .attr("r", 0)
    .remove();

  svg.select("g.x.axis").transition().duration(1000).call(xAxis)
      .attr("transform", "translate(0," + height + ")")
     .select('.label')
      .attr("x", width);

  svg.select("g.y.axis").transition().duration(1000).call(yAxis);

  dots.on("mouseover", function(d) {
    tooltip.transition()
      .duration(100)
      .style("opacity", .9);
    tooltip.html("<b>" + d[groupField] + "</b>" + "<br/><em>Spend:</em> " + d.spend.toPrecision(3) + "<br/><em>Functional:</em> " + d.functional.toPrecision(3) + " %" + "<br/><em>Population:</em> " + d.pop_served)
      .style("left", (d3.event.pageX + 15) + "px")
      .style("top", (d3.event.pageY - 28) + "px");
  })
    .on("mouseout", function(d) {

      tooltip.transition()
        .duration(500)
        .style("opacity", 0);
    });
}

function shorten(s, maxlen) {
  if (!s) return s;
  if (!maxlen) maxlen = 10;
  return (s.length > maxlen) ? s.slice(0, maxlen - 3) + "..." : s;
}
