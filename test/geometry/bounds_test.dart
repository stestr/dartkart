library features_test;

import "package:unittest/unittest.dart";
import "package:unittest/html_enhanced_config.dart";
import "package:dartkart/src/geometry.dart";
import "dart:html" hide Point;

main() {
  useHtmlEnhancedConfiguration();
  group("Bounds", () {
    test("- corners", () {
      var b = new Bounds([1,2], [3,4]);
      expect(b.lowerLeft, new Point.from([1,2]));
      expect(b.upperRight, new Point.from([3,4]));
      expect(b.upperLeft, new Point.from([1,4]));
      expect(b.lowerRight, new Point.from([3,2]));
    });
  });
}

