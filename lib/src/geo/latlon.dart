part of dartkart.geo;

/// true if [lat] is a valid latitude in the range -90..90
bool isValidLat(num lat) => lat >= -90 && lat <= 90;

/// true if [lon] is a valid longitude in the range -180..180
bool isValidLon(num lon) => lon >= -180 && lon <= 180;

/**
 * An instance of this class represents a pair of geodetic
 * coordinates (lat/lon).
 */
class LatLon {

  double _lat;
  double _lon;

  /**
   * Creates a point with coordinates [lat] and [lon].
   *
   * Throws [ArgumentError] if either [lat] or [lon] isn't in the expected
   * range.
   */
  LatLon(num lat, num lon) {
    if (!isValidLat(lat)) throw new ArgumentError("invalid lat value, got $lat");
    if (!isValidLon(lon)) throw new ArgumentError("invalid lon value, got $lon");
    this._lat = lat.toDouble();
    this._lon = lon.toDouble();
  }

  /**
   * A (lon/lat) point at position (0,0).
   */
  LatLon.origin() :
    _lat = 0.0, _lon = 0.0;

  /**
   * Creates a lat/lon point from another value [other].
   * [other] must not be null.
   *
   * ## [other] - possible values
   *
   * * another [LatLon]
   * * a [List] with two numbers lat, lon
   * * a [Map] with two properties `lat` and `lon` of type [num].
   *
   * ## Examples
   *
   *     var ll1 = new LatLon.from([0, 12.32]);
   *     var ll2 = new LatLon.from({"lat": 0, "lon": 12.32});
   *     var ll3 = new LatLon.from(ll1);
   */
  factory LatLon.from(other) {
    if (other == null) throw new ArgumentError("other must not be null");
    if (other is List) {
      return new LatLon._fromList(other);
    } else if (other is Map) {
      return new LatLon._fromMap(other);
    } else if (other is LatLon) {
      return new LatLon(other.lat, other.lon);
    } else {
      throw new ArgumentError("can't create a LonLat from $other");
    }
  }

  factory LatLon._fromList(l) {
    if (l.length != 2)  {
      throw new ArgumentError(
        "expected list with exactly two arguments, got ${l.length}"
      );
    }
    //TODO: check arguments
    return new LatLon(l[0], l[1]);
  }

  factory LatLon._fromMap(map) {
    //TODO: check arguments
    return new LatLon(map["lat"], map["lon"]);
  }

  /// the latitue
  double get lat => _lat;

  /// the longitude
  double get lon => _lon;

  bool operator ==(other) {
    if (other == null || other is! LatLon) return false;
    return lat == other.lat && lon == other.lon;
  }

  String toString() => "{LatLon: lon=$lon, lat=$lat}";
}
