function initMap(){
    //cartodb.createVis('testmap', 'http://documentation.cartodb.com/api/v2/viz/2b13c956-e7c1-11e2-806b-5404a6a683d5/viz.json');
  
    var map = new L.Map('cartodbMap', { 
        center: [-6.822921,39.26966140],
        zoom: 8
    })
    //map.setZoom(zoom+1);

    L.tileLayer('https://dnv9my2eseobd.cloudfront.net/v3/cartodb.map-4xtxp73f/{z}/{x}/{y}.png', {
        attribution: 'Mapbox <a href="http://mapbox.com/about/maps" target="_blank">Terms &amp; Feedback</a>'
    }).addTo(map);

    var layerUrl = 'http://worldbank.cartodb.com/api/v2/viz/9af2a2ec-e414-11e3-94c5-0edbca4b5057/viz.json';

    // change the query for the first layer
    var subLayerOptions = {
        sql: "SELECT * FROM example_cartodbjs_1 where adm0_a3 = 'USA'",
        cartocss: "#example_cartodbjs_1{marker-fill: #109DCD; marker-width: 5; marker-line-color: white; marker-line-width: 0;}"
    }

    cartodb.createLayer(map, layerUrl)
        .addTo(map)
        .on('done', function(layer) {
            //layer.getSubLayer(0).set(subLayerOptions);
        }).on('error', function(err) {
            console.log(err)
        });

}
