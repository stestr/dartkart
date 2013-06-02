library test_SphericalMercator;

import "package:unittest/unittest.dart";
import "package:unittest/html_enhanced_config.dart";
import "dart:math";

import "../../lib/src/geo.dart";
import "../../lib/src/geometry.dart";

main() {
  useHtmlEnhancedConfiguration();
  group("project -", () {
     var proj = new SphericalMercator();
     test("origin should be projected to origin", () {
       var p = proj.project(new LatLon.origin());
       expect(p.truncate(), new Point2D.origin());
     });

     test("project (0, min lat)", () {
       var p = proj.project(new LatLon(-85.0511287798,0));
       expect(p.x, 0);
       expect(p.y.round(), -20037508);
     });

     test("project (0, max lat)", () {
       var p = proj.project(new LatLon(85.0511287798,0));
       expect(p.x, 0);
       expect(p.y.round(), 20037508);
     });

     test("project (min lon, 0)", () {
       var p = proj.project(new LatLon(0,-180));
       expect(p.x.round(), -20037508);
       expect(p.y.round(), 0);
     });

     test("project (max lon, 0)", () {
       var p = proj.project(new LatLon(0,180));
       expect(p.x.round(), 20037508);
       expect(p.y.round(), 0);
     });
  });

  group("unproject -", () {
     var proj = new SphericalMercator();
     test("origin should be unprojected to origin", () {
       var ll = proj.unproject(new Point2D.origin());
       expect(ll, equals(new LatLon.origin()));
     });

     test("unproject (min x, min y)", () {
       var ll = proj.unproject(new Point2D(-20037508, -20037508));
       expect(ll.lat.round(), -85);
       expect(ll.lon.round(), -180);
     });

     test("unproject (max x, max y)", () {
       var ll = proj.unproject(new Point2D(20037508, 20037508));
       expect(ll.lat.round(), 85);
       expect(ll.lon.round(), 180);
     });
  });
}

