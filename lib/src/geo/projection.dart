part of dartkart.geo;

/**
 * An abstract projection
 */
abstract class Projection {
  /**
   * Project a point (lat/lon) from a geodetic coordinates into a
   * Point2D (x,y) in a projected coordinate system
   */
  Point2D project(LatLon ll);

  /**
   * Reverse project a Point2D (x,y) from a projected coordinate system into
   * a Point2D (lat/lon) in the geodetic coordinate system.
   */
  LatLon unproject(Point2D p);
}

/**
 * Spherical Mercator is a popular map projection.
 *
 * It projects (lat, lon)-coordinates to a square whose sides
 * each measure ~40'000km (the earths circumference). The units of the
 * returned x/y-coordinates is *meters*.
 *
 *
 *               (20'000km, 20'000km
 *       +-------o
 *       |       |
 *       |       |
 *       o-------+
 *  (-20'000km, -20'000km
 *
 */
class SphericalMercator implements Projection {
  static const double _MAX_LATITUDE = 85.0511287798;
  static const double _DEG_TO_RAD =  PI / 180;
  static const double _RAD_TO_DEG = 180 / PI;
  /// half earth circumference in meters
  static const double _HEC = 20037508.34;

  /**
   * Transforms geographic coordinates [ll] into projected coordinates.
   *
   * The projected coordinates are in degrees with the following ranges:
   *
   * * minx=-20037508.34, maxx = 20037508.34
   * * miny=-20037508.34, maxy = 20037508.34
   */
  Point2D project(LatLon ll) {
    // make sure lat is in the range [-_MAX_LATITUDE, _MAX_LATIDUDE]
    var lat = max(min(_MAX_LATITUDE, ll.lat), -_MAX_LATITUDE);
    var x = ll.lon / 180 * _HEC;
    var y = log(tan((90 + ll.lat) * PI / 360)) / PI;
    y *= _HEC;
    y = max(-_HEC, min(_HEC, y));
    return new Point2D(x, y).truncate(8);
  }

  /**
   * Transforms projected coordinates into geographic coordinates.
   *
   * Both coordinates [p].x and [p].y should be in the
   * range (-20037508.34,+20037508.34).
   */
  LatLon unproject(Point2D p) {
    var lon = p.x * 180 / _HEC ;
    var lat = 180 / PI * (2 * atan(exp(p.y / _HEC * PI)) - PI/2);
    return new LatLon(lat, lon);
  }
}

/**
 * Trivial equirectangular (Plate Carree) projection.
 *
 * The units of the projected x/y-coordinates is *degrees*,
 * where
 * * -180 <= x <= 180
 * *  -90 <= y <= -90
 */
class PlateCarree implements Projection {
  Point2D project(LatLon ll) => new Point2D(ll.lon, ll.lat);
  LatLon unproject(Point2D p) => new LatLon(p.y, p.x);
}




