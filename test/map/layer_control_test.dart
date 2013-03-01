import "dart:html";
import "dart:math" as math;
import "dart:svg" hide Point;
import "dart:async";
import "dart:collection";
import "package:unittest/unittest.dart";
import "package:unittest/html_enhanced_config.dart";

import "../../lib/src/layer.dart";
import "../../lib/src/geometry.dart";
import "../../lib/src/geo.dart";
import "../../lib/src/core.dart";
import "../../lib/src/map.dart";


class TestLayer extends Layer {
  TestLayer() : super();
  render() {}
}

main() {
  group("basic tests", () {
    var map;
    var container;

    setUp(() {
      container = new DivElement();
      container.id = "map";
      query("body").children.add(container);
      map = new MapViewport("#map");
    });

    tearDown(() {
      query("body").children.remove(container);
    });

    test("- create it", () {
      var control = new LayerControl();
    });

    test("- attach/detach cycle on a map with no layers", () {
      var control = new LayerControl();
      control.attach(map);
      control.detach();
    });
 });

  group("tests on a map with three layers", () {
    var map;
    var container;
    var layers;

    setUp(() {
      container = new DivElement();
      container.id = "map";
      query("body").children.add(container);
      map = new MapViewport("#map");
      layers = [new TestLayer(), new TestLayer(), new TestLayer()];
      layers.forEach((l) => map.addLayer(l));
    });

    tearDown(() {
      layers.forEach((l) => map.removeLayer(l));
      query("body").children.remove(container);
    });

    test("- attach/detach cycle", () {
      var control = new LayerControl();
      control.attach(map);
      var rows = control.root.queryAll("tr");
      expect(rows.length, 3, reason: "Expected 3 table rows");
      control.detach();
    });

    test("- adding a layer", () {
      var layer = new TestLayer();
      var control = new LayerControl();
      control.attach(map);
      map.addLayer(layer);
      var rows = control.root.queryAll("tr");
      expect(rows.length, 4, reason: "Expected 4 table rows");
      var name = rows[3].queryAll("td")[1].query("span").innerHtml;
      expect(name, layer.name, reason: "Unexpected layer name in view");
    });

    test("- removing a layer", () {
      var layer = new TestLayer();
      var control = new LayerControl();
      control.attach(map);
      map.removeLayer(layers[0]);
      var rows = control.root.queryAll("tr");
      expect(rows.length, 2, reason: "Expected 2 table rows");
      var name = rows[0].queryAll("td")[1].query("span").innerHtml;
      expect(name, layers[1].name, reason: "Unexpected layer name in view");
    });

    test("- changing the name of a layer", () {
      var control = new LayerControl();
      control.attach(map);
      layers[0].name ="new name";
      var rows = control.root.queryAll("tr");
      var name = rows[0].queryAll("td")[1].query("span").innerHtml;
      expect(name, layers[0].name, reason: "Unexpected layer name in view");
    });

    test("- changing the visibility of a layer", () {
      var control = new LayerControl();
      control.attach(map);
      layers[0].visible = false;
      var rows = control.root.queryAll("tr");
      var cb = rows[0].query("input");
      expect(cb.attributes["checked"], null,
          reason: "Shouldn't have an attribute checked");

      layers[0].visible = true;
      expect(cb.attributes["checked"], "checked",
          reason: "Should have an attribute checked");

      layers[0].visible = false;
      expect(cb.attributes["checked"], null,
          reason: "Shouldn't have an attribute checked");
    });
 });

}

