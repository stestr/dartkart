library test_multi_layer;

import "package:dartkart/dartkart.dart";
import "dart:async";
import "dart:html";


main() {
  var map = new MapViewport("#sample-map");
  map
    ..zoom = 8
    ..center = new LatLon(46.8, 8);
  
  var source = "http://a.tile.openstreetmap.org/{z}/{x}/{y}.png";
  var osmLayer = new OsmTileLayer(tileSources:source);

  
  var serviceUrl = "https://wms.geo.admin.ch?";
  var wmsLayer = new WMSLayer(
      serviceUrl: serviceUrl,
      layers: "ch.are.gemeindetypen"
  );
  wmsLayer.opacity = 0.4;

  map
    ..addLayer(osmLayer)
    ..addLayer(wmsLayer);
  
  var zoom = new ZoomControl()
    ..attach(map);
  
  var scale = new ScaleIndicatorControl()
    ..attach(map);
  
  var pan = new PanControl()
    ..attach(map);
  
  var layerControl = new LayerControl()
    ..attach(map);
}


