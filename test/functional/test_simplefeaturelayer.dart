
import "dart:html";
import "package:dartkart/src/map.dart";
import "package:dartkart/src/layer.dart";
import "package:dartkart/src/geo.dart";
import "package:dartkart/src/geometry.dart";
import "dart:async";
import "dart:json" as json;
import "../test_config.dart" as config;

var m;
var tfZoomLevel;
var tfLat;
var tfLon;

main() {
  m = new MapViewport("#sample-map");
  var layer = new SimpleFeatureLayer();
  m.addLayer(layer);

  HttpRequest.getString(
      "${config.DARTKART_ROOT}/test/data/countries.geo.json"
  ).then((content) {
    var countries = parseGeoJson(content);
    layer.data  = countries;
  });
}





