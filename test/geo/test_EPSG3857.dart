library test_EPSG3857;

import "package:unittest/unittest.dart";
import "package:unittest/html_enhanced_config.dart";
import "dart:math";

import "../../lib/src/geo.dart";
import "../../lib/src/geometry.dart";

main() {
  useHtmlEnhancedConfiguration();
  group("project", () {
     var crs = new EPSG3857();
     test("project origin at zoom level 0", () {
       var p = crs.project(new LatLon.origin());
       expect(p, equals(new Point2D(0,0)));
     });
  });
}

