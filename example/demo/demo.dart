
import "package:dartkart/dartkart.dart";
import "dart:async";
import "dart:html";


main() {
  var map = new MapViewport("#demo-map");
  map
    ..zoom = 8
    ..center = new LatLon(46.8, 8);

  var source = "http://a.tile.openstreetmap.org/{z}/{x}/{y}.png";
  var osmLayer = new OsmTileLayer(tileSources:source);
  osmLayer.name = "OSM map tiles";

  var serviceUrl = "https://wms.geo.admin.ch?";
  var wmsLayer = new WMSLayer(
      serviceUrl: serviceUrl,
      layers: "ch.are.gemeindetypen"
  );
  wmsLayer.name = "Types of Swiss communities";
  wmsLayer.opacity = 0.4;

  map.addLayer(osmLayer);
  /* hack -
   * addLayer(osmLayer);
   * addLayer(wmsLayer);
   * --> osmlayer isn't displayed initially, only after the first
   * mouse click
   */
//  Timer.run(() {
//    map.addLayer(osmLayer);
////    new Timer( new Duration(milliseconds: 10), () {
////      map.addLayer(wmsLayer);
////    });
//  });
  var pan = new PanControl();
  pan.attach(map);
  pan.placeAt(20,20);

  var zoom = new ZoomControl();
  zoom.attach(map);
  zoom.placeAt(60, 150);

  var scale = new ScaleIndicatorControl();
  scale.attach(map);
  scale.placeAt(20, 500);

  var layerControl = new LayerControl();
  layerControl.attach(map);
  layerControl.root.style.height = "100px";
  layerControl.placeAt(720, 20);
}


