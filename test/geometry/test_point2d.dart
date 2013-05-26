library test_point2d;

import "package:unittest/unittest.dart";
import "package:unittest/html_enhanced_config.dart";
import "package:dartkart/src/geometry.dart";

main() {
  useHtmlEnhancedConfiguration();
  group("constructors -", () {
    test("with two numbers should work", () {
      var p = new Point2D(1,2);
      expect(p.x, 1);
      expect(p.y, 2);
    });

    test("from a list [1,2] should work", () {
      var p = new Point2D.from([1,2]);
      expect(p.x, 1);
      expect(p.y, 2);
    });

    test("from another point should work", () {
      var p1 = new Point2D(1,2);
      var p = new Point2D.from(p1);
      expect(p.x, 1);
      expect(p.y, 2);
      expect(p == p1, true);
      expect(identical(p,p1), false, reason: "p1 should be a copy");
    });
  });
}
