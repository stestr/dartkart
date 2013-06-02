
import "dart:html";
import "package:dartkart/src/map.dart";
import "package:dartkart/src/layer.dart";
import "package:dartkart/src/geo.dart";
import "package:dartkart/src/geometry.dart";
import "dart:async";



var m;
var tfZoomLevel;
var tfLat;
var tfLon;

main() {
  m = new MapViewport("#sample-map");
  m.zoom = 0;
  var source = "http://a.tile.openstreetmap.org/{z}/{x}/{y}.png";
  var layer = new OsmTileLayer(tileSources:source);
  layer.name = "A very long name with a lot of characters";
  m.addLayer(layer);

  var zoom = new ZoomControl()..attach(m);
  var scale = new ScaleIndicatorControl()..attach(m);
  var pan = new PanControl()..attach(m);
  var layerControl = new LayerControl()..attach(m);
}





