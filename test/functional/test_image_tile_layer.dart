library test_image_tile_layer;

import "package:dartkart/src/map.dart";
import "package:dartkart/src/layer.dart";
import "package:dartkart/src/geo.dart";
import "package:dartkart/src/geometry.dart";
import "dart:async";
import "dart:html" hide MouseEvent;


var m;
var tfZoomLevel;
var tfLat;
var tfLon;

main() {
  m = new MapViewport("#sample-map");
  m.zoom = 0;
  var source = "http://a.tile.openstreetmap.org/{z}/{x}/{y}.png";
  var layer = new OsmTileLayer(tileSources:source, renderer: CANVAS_RENDERER);
  m.addLayer(layer);

  wireZoomLevelHandling();
  wireCenterHandling();
  wireOpacityHandling();
}

wireZoomLevelHandling() {
  tfZoomLevel = query("#tfZoomLevel");
  tfZoomLevel.onFocus.listen(selectAll);
  query("#btnZoomLevel").onClick.listen((event) => setZoomLevel());
  query("#btnZoomIn").onClick.listen((e) => zoomIn());
  query("#btnZoomOut").onClick.listen((e) => zoomOut());
}

wireCenterHandling() {
  tfLat = query("#tfLat");
  tfLat.onFocus.listen(selectAll);
  tfLon = query("#tfLon");
  tfLon.onFocus.listen(selectAll);
  query("#btnSetCenter").onClick.listen((event) => setCenter());
}

wireOpacityHandling() {
  var tfOpacity = query("#tfOpacity");
  tfOpacity.onFocus.listen(selectAll);
  query("#btnSetOpacity").onClick.listen((event) => setOpacity());
}

setOpacity() {
  var tfOpacity = query("#tfOpacity");
  try {
    print("field: ${tfOpacity.value}");
    var value = double.parse(tfOpacity.value.trim());
    print("setting opacity: $value");
    m.layers[0].opacity = value;
  } catch(e, st) {
    print(e);
    print(st);
  }
}

selectAll(event) => event.target.select();

zoomIn() => m.zoomIn();
zoomOut() => m.zoomOut();

setZoomLevel() {
  try {
    var zl = int.parse(tfZoomLevel.value.trim());
    if (zl < 0) {
      print("error: illegal zoom level $zl");
      return;
    }
    print("setting zoom level: $zl");
    m.zoom = zl;
    m.render();
  } catch(e) {
    print(e);
  }
}

setCenter() {
  var lat;
  try {
    lat = double.parse(tfLat.value.trim());
    if (!isValidLat(lat)) {
      print("$lat isn't a valid lat");
      return;
    }
  } catch(e) {
    print("illegal lat value: ${tfLat.value}");
    return;
  }
  var lon;
  try {
    lon = double.parse(tfLon.value.trim());
    if (!isValidLon(lon)) {
      print("$lon isn't a valid lon");
      return;
    }
  } catch(e) {
    print("illegal lon value: ${tfLon.value}");
    return;
  }
  m.center = new LatLon(lat,lon);
}



