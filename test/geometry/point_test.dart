library Point_test;

import "package:unittest/unittest.dart";
import "package:unittest/html_enhanced_config.dart";
import "package:dartkart/src/geometry.dart";

main() {
  useHtmlEnhancedConfiguration();
  group("constructors", () {
    test("- with two numbers should work", () {
      var p = new Point(1,2);
      expect(p.x, 1);
      expect(p.y, 2);
    });
    
    test("- from a list [1,2] should work", () {
      var p = new Point.from([1,2]);
      expect(p.x, 1);
      expect(p.y, 2);
    });
    
    test("- from a map {} should work", () {
      var p = new Point.from({"x": 1, "y": 2});
      expect(p.x, 1);
      expect(p.y, 2);
    });

    test("- from another point should work", () {
      var p1 = new Point(1,2);
      var p = new Point.from(p1);
      expect(p.x, 1);
      expect(p.y, 2);
      expect(p == p1, true);
      expect(identical(p,p1), false, reason: "p1 should be a copy");
    });
  });
  
 
  group("integer division", () {
    test("- with rhs als Point should workd", () {
      var p1 = new Point(10,8);
      var p2 = new Point(3,4);
      var p3 = p1 ~/ p2;
      expect(p3, equals(new Point(3,2)));
    });
    test("- with rhs as int should work", () {
      var p1 = new Point(3,4);
      var p3 = p1 ~/ 2.toInt() ;
      expect(p3, equals(new Point(1,2)));
    });
    test("- with rhs as double should work", () {
      var p1 = new Point(3,4);
      var p3 = p1 ~/ 2.toDouble() ;
      expect(p3, equals(new Point(1,2)));
    });
  });
  
  group("multiply", () {
    test("- with rhs as Point should work", () {
      var p1 = new Point(1,2);
      var p2 = new Point(3,4);
      var p3 = p1 * p2;
      expect(p3, equals(new Point(3,8)));
    });
    test("- with rhs as num should work", () {
      var p1 = new Point(1,2);
      var p3 = p1 * 3;
      expect(p3, equals(new Point(3,6)));
    });
  });
  
  group("minus", () {
    test("- with rhs as Point should work", () {
      var p1 = new Point(1,10);
      var p2 = new Point(3,4);
      var p3 = p1 - p2;
      expect(p3, equals(new Point(-2,6)));
    });
    test("- with rhs as num should work", () {
      var p1 = new Point(1,2);
      var p3 = p1 - 3;
      expect(p3, equals(new Point(-2,-1)));
    });
  });
  
  group("plus", () {
    test("- with rhs as Point should work", () {
      var p1 = new Point(1,10);
      var p2 = new Point(3,4);
      var p3 = p1 + p2;
      expect(p3, equals(new Point(4,14)));
    });
    test("- with rhs as num should work", () {
      var p1 = new Point(1,2);
      var p3 = p1 + 3;
      expect(p3, equals(new Point(4,5)));
    });
    test("- with rhs as List should work", () {
      var p1 = new Point(1,2);
      var p3 = p1 + [-4, 7];
      expect(p3, equals(new Point(-3,9)));
    });
  });
}






