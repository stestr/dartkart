library test_map_control;

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
//part "../../lib/src/map/map_viewport.dart";
//part "../../lib/src/map/controls.dart";
import "../../lib/src/map.dart";

class TestControl extends MapControl {
  var _root;
  get root => _root;
  @override
  void build(){
    _root = new DivElement();
  }
  
  get defaultPosition => new Point2D(0,0);
}

main() {
  useHtmlEnhancedConfiguration();
  group("map control tests -", () {
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

    test("placeAt() on unattached map control", () {
      var control = new TestControl();
      control.placeAt(10,20);
      control.attach(map);
      expect(control.root.style.left, "10px");
      expect(control.root.style.top, "20px");
    });

    test("placeAt() on attached map control", () {
      var control = new TestControl();
      control.attach(map);
      control.placeAt(10,20);
      expect(control.root.style.left, "10px");
      expect(control.root.style.top, "20px");
    });
  });
}
