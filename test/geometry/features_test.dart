library features_test;

import "package:unittest/unittest.dart";
import "package:unittest/html_enhanced_config.dart";
import "package:dartkart/src/geometry.dart";
import "dart:html" hide Point;
import "../test_config.dart";

main() {
  useHtmlEnhancedConfiguration();
  group("parse individual object", () {
    test("- Point", () {
      var gjson = """
      {"type": "Point", "coordinates": [1,2]}
      """;
      var o = parseGeoJson(gjson);
      expect(o is Point, true);
      expect(o.x, 1);
      expect(o.y, 2);
    });

    test("- MultiPoint", () {
      var gjson = """
      {"type": "MultiPoint", "coordinates": [[1,2], [3,4], [5,6]]}
      """;
      var o = parseGeoJson(gjson);
      expect(o is MultiPoint, true);
      expect(o.length, 3);
      for (int i=0; i<o.length; i++) {
        expect(o[i] is Point, true);
      }
      expect([o[0].x, o[0].y], [1,2]);
      expect([o[1].x, o[1].y], [3,4]);
      expect([o[2].x, o[2].y], [5,6]);
    });

    test("- LineString", () {
      var gjson = """
      {"type": "LineString", "coordinates": [[1,2], [3,4], [5,6]]}
      """;
      var o = parseGeoJson(gjson);
      expect(o is LineString, true);
      expect(o.length, 3);
      for (int i=0; i<o.length; i++) {
        expect(o[i] is Point, true);
      }
      expect([o[0].x, o[0].y], [1,2]);
      expect([o[1].x, o[1].y], [3,4]);
      expect([o[2].x, o[2].y], [5,6]);
    });

    expectPoints(ls, points) {
      for (int i=0; i< points.length; i++) {
        expect(ls[i].x, points[i][0]);
        expect(ls[i].y, points[i][1]);
      }
    }

    test("- MultiLineString", () {
      var gjson = """
      {"type": "MultiLineString", "coordinates": [
        [[1,2], [3,4], [5,6]],
        [[11,12], [13,14], [15,16]],
        [[21,22], [22,24], [25,26]]
      ]}
      """;
      var o = parseGeoJson(gjson);
      expect(o is MultiLineString, true);
      expect(o.length, 3);
      for (int i=0; i<o.length; i++) {
        expect(o[i] is LineString, true);
      }
      expectPoints(ls, points) {
        for (int i=0; i< points.length; i++) {
          expect(ls[i].x, points[i][0]);
          expect(ls[i].y, points[i][1]);
        }
      }
      expectPoints(o[0], [[1,2], [3,4], [5,6]]);
      expectPoints(o[1], [[11,12], [13,14], [15,16]]);
      expectPoints(o[2], [[21,22], [22,24], [25,26]]);
    });

    test("- Polygon", () {
      var gjson = """
      {"type": "Polygon", "coordinates": [
        [[1,2], [3,4], [5,6], [1,2]],
        [[11,12], [13,14], [15,16], [11,12]],
        [[21,22], [22,24], [25,26], [21,22]]
      ]}
      """;
      var o = parseGeoJson(gjson);
      expect(o is Polygon, true);
      o = (o as Polygon);
      expect(o.exteriorRing, isNotNull);
      expect(o.numInteriorRing, 2);
      expectPoints(o.exteriorRing, [[1,2], [3,4], [5,6]]);
      expectPoints(o.interiorRingN(0), [[11,12], [13,14], [15,16]]);
      expectPoints(o.interiorRingN(1), [[21,22], [22,24], [25,26]]);
    });

    test("- MultiPolygon", () {
      var gjson = """
      {"type": "MultiPolygon", "coordinates": [
        [
          [[1,2], [3,4], [5,6], [1,2]],
          [[11,12], [13,14], [15,16], [11,12]],
          [[21,22], [22,24], [25,26], [21,22]]
        ],
        [
          [[101,102], [103,104], [105,106], [101,102]],
          [[111,112], [113,114], [115,116], [111,112]],
          [[121,122], [123,124], [125,126], [121,122]]
        ],
        [
          [[201,202], [203,204], [205,206], [201,202]],
          [[211,212], [213,214], [215,216], [211,212]],
          [[221,222], [223,224], [225,226], [221,222]]
        ]
      ]}
      """;
      var o = parseGeoJson(gjson);
      expect(o is MultiPolygon, true);
      o = (o as MultiPolygon);
      expect(o.length, 3);
      expect(o[0] is Polygon, true);
      expect(o[1] is Polygon, true);
      expect(o[2] is Polygon, true);
    });


    test("- GeometryCollection", () {
      var gjson = """
      {"type": "GeometryCollection", "geometries": [
        {"type":"Point", "coordinates":[1,2]},
        {"type":"MultiPoint", "coordinates": [[1,2],[3,4]]},
        {"type":"LineString", "coordinates": [[1,2],[3,4],[5,6],[7,8]]}
        ]
      }
      """;
      var o = parseGeoJson(gjson);
      expect(o is GeometryCollection, true);
      o = (o as GeometryCollection);
      expect(o.length, 3);
      expect(o[0] is Point, true);
      expect(o[1] is MultiPoint, true);
      expect(o[2] is LineString, true);
    });

    test("- Feature", () {
      var gjson = """
      {"type": "Feature",
          "geometry":  {"type": "Point", "coordinates": [1,2]},
          "properties": {
             "k1": "string value",
             "k2": 123
          }
      }
      """;
      var o = parseGeoJson(gjson);
      expect(o is Feature, true);
      o = (o as Feature);
      expect(o.geometry is Point, true);
      expect(o.properties["k1"], "string value");
      expect(o.properties["k2"], 123);
    });

    test("- FeatureCollection", () {
      var gjson = """
      {"type": "FeatureCollection",
       "features": [
          {"type": "Feature",
              "geometry":  {"type": "Point", "coordinates": [1,2]},
              "properties": {
                 "k1": "string value",
                 "k2": 123
              }
          },
          {"type": "Feature",
              "geometry":  {"type": "MultiPoint", "coordinates": [[1,2], [3,4], [5,6]]}
          }
       ]
      }
      """;
      var o = parseGeoJson(gjson);
      expect(o is FeatureCollection, true);
      o = (o as FeatureCollection);
      expect(o.features.length, 2);
      expect(o.features[0].geometry is Point, true);
      expect(o.features[1].geometry is MultiPoint, true);
    });
  });

  group("parse file", () {
    test("- countries.geo.json ", () {
      print("retrieving and parsing 'test/data/countries.geo.json'");
      HttpRequest.getString("${DARTKART_ROOT}/test/data/countries.geo.json").then(
          expectAsync1((data) {
        var objs = parseGeoJson(data);
      }));
    });
  });
}
