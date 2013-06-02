library test_geo;

import "package:unittest/unittest.dart";
import "test_EPSG3857.dart" as test_EPSG3857;
import "test_SphericalMercator.dart" as test_SphericalMercator;

main() {
  test_EPSG3857.main();
  test_SphericalMercator.main();
}

