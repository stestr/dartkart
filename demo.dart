import "package:dartkart/dartkart.dart";
import "dart:async";
import "dart:html";


clickHandler(btn) => (evt) {
  queryAll(".btn-demo").forEach((b) => b.classes.remove("active"));
  queryAll(".div-demo").forEach((d) => d.style.display="none");
  btn.classes.add("active");
  switch(btn.attributes["id"]) {
    case "btn-demo-1": query("#div-demo-1").style.display="block"; break;
    case "btn-demo-2": 
      query("#div-demo-2").style.display="block"; 
      map2.render();
      break;
  }
};

mainDemoPage() {
  prepareDemo1();
  prepareDemo2();
  queryAll(".btn-demo").forEach((b) => b.onClick.listen(clickHandler(b)));
  query("#btn-demo-1").classes.add("active");
  query("#div-demo-1").style.display = "block";
  query("#div-demo-2").style.display = "none";
  map1.render();
}

var map1;

prepareDemo1() {
  map1 = new MapViewport("#demo1-map");
  map1
    ..zoom = 7
    ..center = new LatLon(46.8, 8);

  var source = "http://c.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png";
  var osmLayer = new OsmTileLayer(tileSources:source);
  osmLayer.name = "OSM map tiles";
  Timer.run(() {
    map1.addLayer(osmLayer);
  });
  new PanControl().attach(map1);
  new ZoomControl().attach(map1);
  new ScaleIndicatorControl().attach(map1);
}

var map2;

prepareDemo2() {
  map2 = new MapViewport("#demo2-map");
  map2
    ..zoom = 7
    ..center = new LatLon(46.8, 8);

  var source = "http://a.tile.openstreetmap.org/{z}/{x}/{y}.png";
  var osmLayer = new OsmTileLayer(tileSources:source);
  osmLayer.name = "OSM map tiles";
  osmLayer.opacity = 0.6;

  var serviceUrl = "https://wms.geo.admin.ch?";
  var wmsLayer = new WMSLayer(
      serviceUrl: serviceUrl,
      layers: "ch.are.gemeindetypen",
      parameters: {}
  );
  wmsLayer.name = "Types of Swiss communities";
  wmsLayer.opacity = 0.6;

  /* hack -
   * addLayer(osmLayer);
   * addLayer(wmsLayer);
   * --> osmlayer isn't displayed initially, only after the first
   * mouse click
   */
  Timer.run(() {
    map2.addLayer(osmLayer);
    new Timer( new Duration(milliseconds: 10), () {
      map2.addLayer(wmsLayer);
    });
  });
  new PanControl().attach(map2);
  new ZoomControl().attach(map2);
  new ScaleIndicatorControl().attach(map2);
  var layerControl = new LayerControl(map2);
  layerControl.root.style.height="100px";
}

/**
* The entry point for the main start page 
*/
mainStartPage() {
  var map = new MapViewport("#startpage-map");
  map
    ..zoom = 7
    ..center = new LatLon(46.8, 8);

  var source = "http://a.tile.openstreetmap.org/{z}/{x}/{y}.png";
  var osmLayer = new OsmTileLayer(tileSources:source);
  osmLayer.name = "OSM map tiles";
  map.addLayer(osmLayer);
  new SimpleZoomControl(map);
}

main() {
  var id = query("body").attributes["id"];
  switch(id) {
    case "main": mainStartPage(); break;
    case "demo": mainDemoPage(); break;
  }
}