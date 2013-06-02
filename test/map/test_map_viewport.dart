library test_map_viewport;

import "dart:html" hide Point;
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
  useHtmlEnhancedConfiguration();
  group("layer functionality -", () {
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

    test("adding a layer", () {
      var layer = new TestLayer();
      map.onLayersChanged.listen(expectAsync1((e) {
        expect(e.type, LayerEvent.ADDED);
        expect(e.map, map);
        expect(e.layer, layer);
      }));
      map.addLayer(layer);
      expect(map.layers.length, 1);
      expect(map.layers[0], layer);
      expect(layer.map, map);
    });

    test("removing a layer", () {
      var layer = new TestLayer();
      map.addLayer(layer);
      map.onLayersChanged.listen(expectAsync1((e) {
        expect(e.type, LayerEvent.REMOVED);
        expect(e.map, map);
        expect(e.layer, layer);
      }));
      map.removeLayer(layer);
      expect(map.layers.length, 0);
      expect(layer.map, null);
    });
  });
}




