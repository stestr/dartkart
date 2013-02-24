part of dartkart.geo;

/**
 * An instance of this class represents a rectangular are in geograpic
 * coordinates (lat/lon).
 */
class LatLonBounds {
  double _minLat;
  double _minLon;
  double _maxLat;
  double _maxLon;

  /**
   * Creates the bounds given the southwest corner [min]
   * and the northeast corner [max].
   *
   * Both [min] are [max] must be objects accepted by
   * [LatLon.from].
   *
   * ## Examples
   *     var b1 = new LatLonBounds(new LonLat(0,0), new LonLat(1,1));
   *     var b1 = new LatLonBounds([0,0], [1,1]);
   *     var b1 = new LatLonBounds({"lon": 0, "lat": 0}, {"lon": 1, "lat": 1});
   */
  LatLonBounds(min, max) {
    min = new LatLon.from(min);
    max = new LatLon.from(max);
    _minLat = min.lat;
    _minLon = min.lon;
    _maxLat = max.lat;
    _maxLon = max.lon;
  }


  /**
   * Create a bounds objects from another value [other].
   *
   * ## Possible values for [other]
   * * a [LatLonBounds] -> creates a copy of [other]
   */
  factory LatLonBounds.from(other) {
    if (other is LatLonBounds) {
      return new LatLonBounds(
        other.southWest,
        other.northEast
      );
    }
    throw new ArgumentError("can't create a LatLonBounds from $other");
  }

  /// the south-west corner 
  LatLon get southWest => new LatLon(_minLat, _maxLon);
  /// the south-east corner 
  LatLon get southEast => new LatLon(_minLat, _maxLon);
  /// the north-east corner 
  LatLon get northEast => new LatLon(_maxLat, _maxLon);
  
  /// the north-west corner 
  LatLon get northWest => new LatLon(_minLat, _maxLon);
  
  /// the center point 
  LatLon get center => new LatLon((_minLat + _maxLat) / 2, (_minLon + _maxLon) / 2);

  _containsPoint(LatLon p) =>
         p.lat >= _minLat && p.lat <= _maxLat
      && p.lon >= _minLon && p.lon <= _maxLon;

  _containsBounds(LatLonBounds b) => _containsPoint(b.southWest)
       && _containsPoint(b.northEast);

  /**
   * Checks wheter [obj] is within this bounds.
   *
   * ## Possible values for [obj]
   * * a [LatLon] -> checks whether the point is this bounds
   * * a [LatLonBounds] -> checks whether the bounds are completely in this
   *   bounds
   *    
   * Throws [ArgumentError] if [obj] is either null or of an
   * unexpected type.
   */
  bool contains(obj) {
    if (obj is LatLon) return _containsPoint(obj);
    if (obj is LatLonBounds) return _containsBounds(obj);
    throw new ArgumentError("expected LatLon or LatLonBounds, got $obj");
  }

  /**
   * Checks wheter [n] interesects with this bounds.
   *
   * Replies true, if [b] interesects, false otherwise.
   * Throws [ArgumentError] if [b] is null or of an unexpected type
   */
  bool intersects(LatLonBounds b) {
    if (b == null) throw new ArgumentError("b must not be null");
    return _containsPoint(b.southWest) || _containsPoint(b.southEast)
        || _containsPoint(b.northWest) || _containsPoint(b.northEast);
  }
}