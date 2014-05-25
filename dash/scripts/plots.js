//Only used for basic testing
function init() {
  d3.json("http://localhost:5000/api/waterpoints/stats_by/district?region=Arusha", function(error, wpdata) {
    drawPlots(wpdata);
  });
}


function drawPlots(wpdata) {
  doughnut("#doughnut");
  //parallelAxis("parallelAxis",wpdata);
  plotStatusSummary("#statusPerDistrict", "Arusha");
  spendVsStatus("#spendVsStatus", wpdata);
  spendPerDistrict("#spendPerDistrict", wpdata);
  statusOverTime("#statusOverTime");
  districtRanking("#districtRanking", wpdata);
}

function doughnut(selector) {

  d3.json("http://localhost:5000/api/waterpoints/status", function(error, data) {

    var sum = d3.sum(data, function(x) {
      return x.count;
    });

    //take svg size from parent size
    var h = $(selector).height();
    var w = $(selector).width();

    var margin = {
        top: 20,
        right: 20,
        bottom: 20,
        left: 20
      },
      width = w - margin.left - margin.right,
      height = h - margin.top - margin.bottom;

    var radius = Math.min(width, height) / 2;
    var outerRadius = radius - 10;
    var innerRadius = radius - 70;

    var color = d3.scale.category10();
    var svg;

    //create the svg if it does not already exist
    if ($(selector + " svg").length < 1) {
      svg = d3.select(selector).append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
      //transform within the margins
      .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
      //transform to the center
      .append("g")
        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
    } else {
      svg = d3.select(selector + " svg g g");
    }

    //bind the data
    svg.data();

    var arc = d3.svg.arc()
      .innerRadius(innerRadius)
      .outerRadius(outerRadius);

    var pie = d3.layout.pie()
      .value(function(d) {
        return d.count;
      });

    var arcs = svg.selectAll("g.slice")
      .data(pie(data))
      .enter()
      .append("svg:g")
      .attr("class", "slice");

    var tip = d3.tip()
      .attr("class", "d3-tip")
      .html(String);

    var formatter = d3.format(".1%");

    // setup the labels in the center of the doughnut hole
    svg.append("text")
      .attr("id", "status")
      .attr("class", "label")
      .attr("y", -10)
      .attr("x", 0)
      .html("Total Waterpoints");
    svg.append("text")
      .attr("id", "waterpoint")
      .attr("class", "waterpoint")
      .attr("y", 40)
      .attr("x", 0)
      .html(sum);

    // Draw the slices (arcs)
    arcs.append("svg:path")
      .call(tip)
      .attr("fill", function(d, i) {
        return color(i);
      })
      .attr("d", arc)
      .on("mouseover", function(d, i) {
        // Show the tooltip
        tip.show(formatter(d.data.count / sum));
        // Update the doughnut hole label with slice meta data
        svg.select("#status").remove();
        svg.select("#waterpoint").remove();
        svg.append("text")
          .attr("id", "status")
          .attr("class", "label")
          .attr("y", -10)
          .attr("x", 0)
          .html(d.data.status);
        svg.append("text")
          .attr("id", "waterpoint")
          .attr("class", "waterpoint")
          .attr("y", 40)
          .attr("x", 0)
          .html(d.data.count);
      })

    .on("mouseout", function(d) {
      // Remove the tooltip
      tip.hide();
      // Return the doughnut hole label to the default label
      svg.select("#status").remove();
      svg.select("#waterpoint").remove();
      svg.append("text")
        .attr("id", "status")
        .attr("class", "label")
        .attr("y", -10)
        .attr("x", 0)
        .html("Total Waterpoints");
      svg.append("text")
        .attr("id", "waterpoint")
        .attr("class", "waterpoint")
        .attr("y", 40)
        .attr("x", 0)
        .html(sum);
    });

  });
}

function parallelAxis(selector, data) {
  var dims = ["district", "funder", "source_type", "status"];
  var types = ["string", "string", "string", "string"];
  var typemap = _.object(dims, types);
  var colorgen = d3.scale.category20();
  var colors = {};

  _.chain(data)
    .pluck('district')
    .uniq()
    .each(function(d, i) {
      colors[d] = colorgen(i);
    });

  var color = function(d) {
    return colors[d.district];
  };

  var h = $(selector).height();
  var w = $(selector).width();

  var margin = {
      top: 20,
      right: 20,
      bottom: 40,
      left: 20
    },
    width = w - margin.left - margin.right,
    height = h - margin.top - margin.bottom;

  var x = d3.scale.ordinal().rangePoints([0, width], 1),
    y = {},
    dragging = {};

  var line = d3.svg.line(),
    axis = d3.svg.axis().orient("left"),
    background,
    foreground;

  var color = d3.scale.category20b();
  var svg;

  if ($(selector + " svg").length < 1) {
    svg = d3.select(selector).append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
    //transform within the margins
    .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
  } else {
    svg = d3.select(selector + " svg g");
  }

  // Extract the list of dimensions and create a scale for each.
  x.domain(dims);

  dims.forEach(function(x) {
    y[x] = d3.scale.ordinal()
      .range([h, 0]);
  });

  // Add grey background lines for context.
  background = svg.append("g")
    .attr("class", "background")
    .selectAll("path")
    .data(data)
    .enter().append("path")
    .attr("d", path);

  // Add blue foreground lines for focus.
  foreground = svg.append("g")
    .attr("class", "foreground")
    .selectAll("path")
    .data(data)
    .enter().append("path")
    .attr("d", path);

  // Add a group element for each dimension.
  var g = svg.selectAll(".dimension")
    .data(dims)
    .enter().append("g")
    .attr("class", "dimension")
    .attr("transform", function(d) {
      return "translate(" + x(d) + ")";
    })
    .call(d3.behavior.drag()
      .on("dragstart", function(d) {
        dragging[d] = this.__origin__ = x(d);
        background.attr("visibility", "hidden");
      })
      .on("drag", function(d) {
        dragging[d] = Math.min(w, Math.max(0, this.__origin__ += d3.event.dx));
        foreground.attr("d", path);
        dims.sort(function(a, b) {
          return position(a) - position(b);
        });
        x.domain(dims);
        g.attr("transform", function(d) {
          return "translate(" + position(d) + ")";
        })
      })
      .on("dragend", function(d) {
        delete this.__origin__;
        delete dragging[d];
        transition(d3.select(this)).attr("transform", "translate(" + x(d) + ")");
        transition(foreground)
          .attr("d", path);
        background
          .attr("d", path)
          .transition()
          .delay(500)
          .duration(0)
          .attr("visibility", null);
      }));

  // Add an axis and title.
  g.append("g")
    .attr("class", "axis")
    .each(function(d) {
      d3.select(this).call(axis.scale(y[d]));
    })
    .append("text")
    .attr("text-anchor", "middle")
    .attr("y", -9)
    .text(String);

  // Add and store a brush for each axis.
  g.append("g")
    .attr("class", "brush")
    .each(function(d) {
      d3.select(this).call(y[d].brush = d3.svg.brush().y(y[d]).on("brushstart", brushstart).on("brush", brush));
    })
    .selectAll("rect")
    .attr("x", -8)
    .attr("width", 16);


  function position(d) {
    var v = dragging[d];
    return v == null ? x(d) : v;
  }

  function transition(g) {
    return g.transition().duration(500);
  }

  // Returns the path for a given data point.
  function path(d) {
    return line(dims.map(function(p) {
      return [position(p), y[p](d[p])];
    }));
  }

  // When brushing, don’t trigger axis dragging.
  function brushstart() {
    d3.event.sourceEvent.stopPropagation();
  }

  // Handles a brush event, toggling the display of foreground lines.
  function brush() {
    var actives = dims.filter(function(p) {
        return !y[p].brush.empty();
      }),
      extents = actives.map(function(p) {
        return y[p].brush.extent();
      });
    foreground.style("display", function(d) {
      return actives.every(function(p, i) {
        return extents[i][0] <= d[p] && d[p] <= extents[i][1];
      }) ? null : "none";
    });
  }
}

/*
 * Stacked bar chart summarizing the status (functional/non functional)
 * of all the waterpoints in the given region/district (both may be empty)
 */
function plotStatusSummary(selector, region, district) {
  var url = "http://localhost:5000/api/waterpoints/stats_by/";
  var groupField;

  if (region && district) {
    groupField = "ward";
    url += groupField + "?region=" + region + "&district=" + district;
  } else if (region) {
    groupField = "district";
    url += groupField + "?region=" + region;
  } else if (district) {
    //Note: technically not 100% correct as different districts in different regions may share the same name (?)
    groupField = "ward";
    url += groupField + "?district=" + district;
  } else {
    groupField = "region";
    url += groupField;
  }

  d3.json(url, function(error, data) {

    data.forEach(function(group) {
      var y0 = 0;
      //status type is not always in the same order due to mongo, sort here
      group.waterpoints = _.sortBy(group.waterpoints, "status");
      group.waterpoints.forEach(function(x) {
        x.y0 = y0;
        x.y1 = (y0 += x.count);
      });
    });
    data.sort(function(a, b) {
      return b.count - a.count;
    });

    var h = $(selector).height();
    var w = $(selector).width();

    var margin = {
        top: 20,
        right: 20,
        bottom: 80,
        left: 55
      },
      width = w - margin.left - margin.right,
      height = h - margin.top - margin.bottom;

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
      .orient("bottom");

    var yAxis = d3.svg.axis()
      .scale(y)
      .orient("left");

    var color = d3.scale.category20();

    //create the svg if it does not already exist
    if ($(selector + " svg").length < 1) {
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
        .attr("y", -50)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text("Number of Waterpoints");
    } else {
      svg = d3.select(selector + " svg g");
    }

    var state = svg.selectAll(".group")
      .data(data, function(d) {
        return d[groupField];
      });

    var rects = state.selectAll("rect")
      .data(function(d) {
        return d.waterpoints;
      }, function(d) {
        return d.status + "_" + d.count;
      })

    var statesEnter = state.enter()
      .append("g")
      .attr("class", "group")
      .attr("transform", function(d) {
        return "translate(" + x(d[groupField]) + ",0)";
      });

    var rectsEnter = statesEnter.selectAll("rect")
      .data(function(d) {
        return d.waterpoints;
      }, function(d) {
        return d.status + "_" + d.count;
      })

    rects.exit()
      .transition()
      .duration(1000)
      .attr("y", y(0))
      .attr("height", 0)
      .remove();

    state.exit()
      .transition()
      .duration(1000)
      .style("opacity", 0)
      .remove();

    rectsEnter.enter().append("rect")
      .attr("width", x.rangeBand())
      .style("fill", function(d) {
        return color(d.status);
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
    var legend = svg.selectAll(".legend")
      .data(color.domain().slice().reverse());

    legend.exit().remove();

    legend.enter().append("g")
      .attr("class", "legend")
      .attr("transform", function(d, i) {
        return "translate(0," + i * 20 + ")";
      });

    legend.append("rect")
      .attr("x", width - 18)
      .attr("width", 18)
      .attr("height", 18)
      .style("fill", color);

    legend.append("text")
      .attr("x", width - 24)
      .attr("y", 9)
      .attr("dy", ".35em")
      .style("text-anchor", "end")
      .text(function(d) {
        return d;
      });
  });
}

function spendPerDistrict(selector, data) {

  //TODO: need real data
  data.forEach(function(x) {
    x.spend = (Math.random() * 10000 / x.count);
  });

  data.sort(function(a, b) {
    return a.spend - b.spend;
  });

  var h = $(selector).height();
  var w = $(selector).width();

  var margin = {
      top: 20,
      right: 20,
      bottom: 80,
      left: 55
    },
    width = w - margin.left - margin.right,
    height = h - margin.top - margin.bottom;

  var x = d3.scale.ordinal()
    .rangeRoundBands([0, width], .1);

  var y = d3.scale.linear()
    .rangeRound([height, 0]);

  x.domain(_.pluck(data, "district"));
  y.domain([0, d3.max(data, function(d) {
    return d.spend;
  })]);

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

  var color = d3.scale.category20();

  if ($(selector + " svg").length < 1) {
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
      .selectAll("text")
      .style("text-anchor", "end")
      .attr("dx", "-.8em")
      .attr("dy", ".15em")
      .attr("transform", function(d) {
        return "rotate(-65)"
      });

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", -50)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("Spend per Waterpoint ($)");
  } else {
    svg = d3.select(selector + " svg g");
  }

  var state = svg.selectAll(".district")
    .data(data)
    .enter().append("g")
    .attr("class", "g")
    .attr("transform", function(d) {
      return "translate(" + x(d.district) + ",0)";
    })
    .append("rect")
    .attr("width", x.rangeBand())
    .attr("y", function(d) {
      return y(0) - y(d.spend);
    })
    .attr("height", function(d) {
      return y(d.spend);
    })
    .style("fill", function(d) {
      return color(d.district);
    });
}

function statusOverTime(selector) {
  var data = [];
  //TODO: need real data
  _.range(2000, 2015).forEach(function(i) {
    data.push({
      date: i.toString(),
      count: 1000,
      status: [{
        status: "Functional",
        count: Math.random() * 500
      }, {
        status: "Not Functional",
        count: Math.random() * 500
      }]
    });
  });

  var parseDate = d3.time.format("%Y").parse;
  data.forEach(function(d) {
    d.date = parseDate(d.date);
  });

  var h = $(selector).height();
  var w = $(selector).width();

  var margin = {
      top: 20,
      right: 50,
      bottom: 30,
      left: 50
    },
    width = w - margin.left - margin.right,
    height = h - margin.top - margin.bottom;

  var x = d3.time.scale()
    .range([0, width])
    .domain(d3.extent(data, function(d) {
      return d.date;
    }));

  var y = d3.scale.linear()
    .range([height, 0])
    .domain([0, d3.max(data, function(d) {
      return d.count;
    })]);

  var color = d3.scale.category20();

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

  var area = d3.svg.area()
    .x(function(d) {
      return x(d.date);
    })
    .y0(function(d) {
      return y(d.y0);
    })
    .y1(function(d) {
      return y(d.y0 + d.y);
    });

  var stack = d3.layout.stack()
    .values(function(d) {
      return d.values;
    });

  if ($(selector + " svg").length < 1) {
    svg = d3.select(selector).append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
    //transform within the margins
    .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", -50)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("Number of Waterpoints");
  } else {
    svg = d3.select(selector + " svg g");
  }

  //TODO hardcoded
  color.domain(["Functional", "Not Functional"]);

  var stati = stack(color.domain().map(function(name) {
    return {
      name: name,
      values: data.map(function(d) {
        return {
          date: d.date,
          y: _.find(d.status, function(x) {
            return x.status == name;
          }).count
        };
      })
    };
  }));

  var status = svg.selectAll(".status")
    .data(stati)
    .enter().append("g")
    .attr("class", "status");

  status.append("path")
    .attr("class", "area")
    .attr("d", function(d) {
      return area(d.values);
    })
    .style("fill", function(d) {
      return color(d.name);
    });

  status.append("text")
    .datum(function(d) {
      return {
        name: d.name,
        value: d.values[d.values.length - 1]
      };
    })
    .attr("transform", function(d) {
      return "translate(" + x(d.value.date) + "," + y(d.value.y0 + d.value.y / 2) + ")";
    })
    .attr("x", -20)
    .attr("dy", ".35em")
    .text(function(d) {
      return d.name;
    });

}

function spendVsStatus(selector, wpdata) {
  //TODO: more made up data
  data = [];
  wpdata.forEach(function(x) {
    var functional = _.find(x.waterpoints, function(x) {
      return x.status == "Functional";
    });
    data.push({
      functional: functional.count / x.count * 100,
      spend: Math.random() * 10000 / x.count,
      district: x.district
    });
  });

  var h = $(selector).height();
  var w = $(selector).width();

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

  var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");


  var color = d3.scale.category20();

  if ($(selector + " svg").length < 1) {
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
    svg = d3.select(selector + " svg g");
  }


  //TODO: use d3.tip
  var tooltip = d3.select("body").append("div")
    .attr("class", "tooltip")
    .style("opacity", 0);

  svg.selectAll(".dot")
    .data(data)
    .enter().append("circle")
    .attr("class", "dot")
    .attr("r", 3.5)
    .attr("cx", function(d) {
      return x(d.spend);
    })
    .attr("cy", function(d) {
      return y(d.functional);
    })
    .style("fill", function(d) {
      return color(d.district);
    })
    .on("mouseover", function(d) {
      tooltip.transition()
        .duration(100)
        .style("opacity", .9);
      tooltip.html(d.district + "<br/> (" + d.spend.toPrecision(3) + ", " + d.functional.toPrecision(3) + ")")
        .style("left", (d3.event.pageX + 5) + "px")
        .style("top", (d3.event.pageY - 28) + "px");
    })
    .on("mouseout", function(d) {
      tooltip.transition()
        .duration(500)
        .style("opacity", 0);
    });
  /*
    // draw legend
    var legend = svg.selectAll(".legend")
    .data(color.domain())
    .enter().append("g")
    .attr("class", "legend")
    .attr("transform", function(d, i) { return "translate(0," + i * 20 + ")"; });

    // draw legend colored rectangles
    legend.append("rect")
    .attr("x", width - 18)
    .attr("width", 18)
    .attr("height", 18)
    .style("fill", color);

    // draw legend text
    legend.append("text")
    .attr("x", width - 24)
    .attr("y", 9)
    .attr("dy", ".35em")
    .style("text-anchor", "end")
    .text(function(d) { return d;})*/

}

function districtRanking(selector, data) {

  //sort by % functional waterpoints
  var comparator = function(a, b) {
    var af = _.find(a.waterpoints, function(x) {
      return x.status == "Functional";
    }).count;
    var bf = _.find(b.waterpoints, function(x) {
      return x.status == "Functional";
    }).count;
    return (bf / b.count) - (af / a.count);
  }
  data.sort(comparator);

  data.forEach(function(x, i) {
    var functional = _.find(x.waterpoints, function(x) {
      return x.status == "Functional";
    });
    x.functional = (functional.count / x.count * 100).toFixed(2);
    x.spend = (Math.random() * 10000 / x.count).toFixed(2);
    x.rank = i + 1;
  })

  var table = d3.select(selector).append("table")
    .attr("class", "table"),
    thead = table.append("thead"),
    tbody = table.append("tbody");

  var header = ["Rank", "% Functional", "Total Waterpoints", "Spend per Waterpoint", "District"];
  var columns = ["rank", "functional", "count", "spend", "district"];

  // append the header row
  thead.append("tr")
    .selectAll("th")
    .data(header)
    .enter()
    .append("th")
    .text(function(d) {
      return d;
    });

  // create a row for each district
  var rows = tbody.selectAll("tr")
    .data(data)
    .enter()
    .append("tr");

  // create a cell in each row for each column
  var cells = rows.selectAll("td")
    .data(function(row) {
      return columns.map(function(x) {
        return {
          column: x,
          value: row[x]
        };
      });
    })
    .enter()
    .append("td")
    .text(function(d) {
      return d.value;
    });
}

//TODO: unfortunately css issues with this plugin
function parallelAxis2(id, data) {
  var selector = "#" + id;
  var dims = ["district", "funder", "source_type", "status"];
  var types = ["string", "string", "string", "string"];
  var typemap = _.object(dims, types);
  var colorgen = d3.scale.category20();
  var colors = {};

  _.chain(data)
    .pluck('district')
    .uniq()
    .each(function(d, i) {
      colors[d] = colorgen(i);
    });

  var color = function(d) {
    return colors[d.district];
  };

  var pc = d3.parcoords()(selector)
    .dimensions(dims)
    .types(typemap)
    .data(data)
    .color(color)
    .alpha(0.4)
    .margin({
      top: 24,
      left: 150,
      bottom: 12,
      right: 0
    })
    .mode("queue")
    .reorderable()
    .brushable()
    .render();

  pc.svg.selectAll("text")
    .style("font", "10px sans-serif");
}
