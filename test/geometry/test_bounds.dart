library test_bounds;

import "package:unittest/unittest.dart";
import "package:unittest/html_enhanced_config.dart";
import "package:dartkart/src/geometry.dart";
import "dart:html";

main() {
  useHtmlEnhancedConfiguration();
  group("corners -", () {
    test("test the four corners", () {
      var b = new Bounds([1,2], [3,4]);
      expect(b.lowerLeft, new Point2D.from([1,2]));
      expect(b.upperRight, new Point2D.from([3,4]));
      expect(b.upperLeft, new Point2D.from([1,4]));
      expect(b.lowerRight, new Point2D.from([3,2]));
    });
  });
}

