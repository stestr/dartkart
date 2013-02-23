library base_test;

import "package:unittest/unittest.dart";
import "package:unittest/html_enhanced_config.dart";
import "dart:html";
import "dart:async";
import "dart:math" as math;
import "dart:collection";
import "package:meta/meta.dart";

import "../../lib/src/map.dart";
import "../../lib/src/core.dart";
import "../../lib/src/geometry.dart";


part "../../lib/src/layer/base.dart";

class TestLayer extends Layer {
  TestLayer() : super();
  render() {}
}

main() {
  useHtmlEnhancedConfiguration();
  
  group("properies - name -", () {
    var layer;
    setUp(() {
      layer = new TestLayer();      
    });
    test("initial name is set", () {
      expect(layer.name.isEmpty, false);
    });
    test("set name triggers notification", () {
      var newname ="newname";
      layer.onPropertyChanged.listen(expectAsync1((e) {
        expect(e.name, "name");
        expect(e.newValue, newname);        
      }));
      layer.name = newname;
    });    
    test("null name results in a standard name", () {
      layer.name = null;
      expect(layer.name.isEmpty, false);
    });
    
    test("empty name results in a standard name", () {
      layer.name = "  ";
      expect(layer.name.isEmpty, false);
    });
  });
  
  group("properies - opacity -", () {
    var layer;
    setUp(() {
      layer = new TestLayer();      
    });
    test("initial opacity is 1.0", () {
      expect(layer.opacity, 1.0);
    });
    test("set opacity ", () {
      layer.opacity = 0.5;
      expect(layer.opacity, 0.5);
    });    
    test("set opacity out of range ", () {
      layer.opacity = 1.1;
      expect(layer.opacity, 1.0);
      
      layer.opacity = -0.1;
      expect(layer.opacity, 0.0);
    });    

    test("set opacity triggers notification", () {
      var value = 0.5;
      layer.onPropertyChanged.listen(expectAsync1((e) {
        expect(e.name, "opacity");
        expect(e.newValue, value);        
      }));
      layer.opacity = value;
    });   
  });
  
  group("attach / detach -", () {
    var layer;
    var map;
    DivElement container;
    
    setUp(() {
      var container = new DivElement();
      container.id = "map";
      query("body").children.add(container);
      layer = new TestLayer();
      map = new MapViewport("#map");
    });
    
    tearDown(() {
      query("body").children.remove(container);
    });
    
    test("running an attach/detach cycle", () {
      expect(layer.map, null);
      layer.attach(map);
      expect(layer.map, map);
      layer.detach();
      expect(layer.map, null);
    });
  });
}



