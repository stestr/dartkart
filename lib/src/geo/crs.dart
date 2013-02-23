part of dartkart.geo;


abstract class CoordinateReferenceSystem {
  /// The standardized identifier for this reference system
  ///
  /// A coordinate references system can be assigned more than
  /// one idetifier, see also [aliases]
  String get code;

  /// A list of code aliases for this reference system.
  ///
  /// The empty list, if no alternative codes are known for this
  /// coordinate reference system.
  List<String> get aliases;
}

/// The abstract base class for a projected coordinate reference systems.
abstract class ProjectedCRS  implements CoordinateReferenceSystem {
  LatLonBounds get geographicBounds;
  Bounds get projectedBounds;

  Point project(LatLon ll);
  LatLon unproject(Point p);
}

/**
 * see [EPSG:3857](http://spatialreference.org/ref/sr-org/6864/)
 */
class EPSG3857 extends ProjectedCRS {
  static final _projection = new SphericalMercator();
  static final _projectedBounds = new Bounds(
      [-20037508.34, -20037508.34],
      [ 20037508.34,  20037508.34]
  );
  static final _geographicBounds = new LatLonBounds(
      new LatLon(-85.0511287798,-180),
      new LatLon(85.0511287798, 180)
  );

  String get code => "EPSG:3857";

  List<String> get aliases => const ["EPSG:900913"];

  Bounds get projectedBounds => _projectedBounds;

  LatLonBounds get geographicBounds => _geographicBounds;

  Point project(LatLon ll) => _projection.project(ll);

  LatLon unproject(Point p) => _projection.unproject(p);
}



