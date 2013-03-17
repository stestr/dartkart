
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

  /* hack -
   * addLayer(osmLayer);
   * addLayer(wmsLayer);
   * --> osmlayer isn't displayed initially, only after the first
   * mouse click
   */
  Timer.run(() {
    map.addLayer(osmLayer);
    new Timer( new Duration(milliseconds: 10), () {
      map.addLayer(wmsLayer);
    });
  });
  //new PanControl(map);
  new SimpleZoomControl(map);
  //new ScaleIndicatorControl(map);
  //new LayerControl(map);
}


