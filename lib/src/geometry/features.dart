part of dartkart.geometry;

/**
 * Geometry is the root feature class.
 */
abstract class Geometry {

}

/**
 * A Curve is a 1-dimensional geometric object usually stored as a sequence
 * of Points, with the subtype of Curve specifying the form of the
 * interpolation between Points.
 */
//TODO make it an iterable
class Curve extends Geometry  {
  List<Point> _points = [];

  Curve(List<Point> points) {
    if (points == null) throw new ArgumentError("points must not be null");
    if (points.any((p) => p == null))  throw new ArgumentError(
        "points must contain nulls");
    if (points.isEmpty) throw new ArgumentError("points must not be empty");
    _points.addAll(points);
  }

  /// the start point of this curve
  Point get startPoint => _points.first;

  /// the end point of this curve
  Point get endPoint => _points.last;

  /// true, if [startPoint] is equal to [endPoint]
  bool get isClosed => startPoint == endPoint;

  ///  The length of this Curve in its associated spatial reference
  /// not yet implemented
  int get spatialLength {
    throw new UnimplementedError();
  }

  /// not yet implemented
  bool get isRing {
    throw new UnimplementedError();
  }

  /// not yet implemented
  bool get isSimple {
    throw new UnimplementedError();
  }

  List<Point> get points => new UnmodifiableListView(_points);
}

/**
 * A LineString is a Curve with linear interpolation between Points.
 * Each consecutive pair of Points defines a Line segment.
 */
class LineString extends Curve {
   LineString(List<Point> points) : super(points);

   /// Returns the specified Point N in this LineString.
   Point pointN(int i) => this[i];

   /// Same as [pointN], for convenience
   Point operator [](i) => _points[i];

   /// The number of Points in this LineString.
   int get numPoints => _points.length;
   int get length => numPoints;
}

/**
 * A Line is a LineString with exactly 2 Points.
 */
// TODO: complete later
class Line extends LineString {
  Line(List<Point> points) : super(points) {
    //TODO: make sure it has only two points
  }
}


/**
 * A LinearRing is a LineString that is both closed and simple.
 */
//TODO: complete later
class LinearRing extends LineString {
  LinearRing(List<Point> points) : super(points) {
    //TODO: make sure this is a simple, closed line string
  }
}

/**
 * A GeometryCollection is a geometric object that is a collection of some
 * number of geometric objects.
 *
 * All the elements in a GeometryCollection shall be in the same Spatial
 * Reference System. This is also the Spatial Reference System for the
 * GeometryCollection.
 */
//TODO: make it an iterable
class GeometryCollection extends Geometry {
  List<Geometry> _geometries = [];

  GeometryCollection(Collection<Geometry> geometries) {
    if (geometries == null) return;
    geometries.remove(null);
    _geometries.addAll(geometries);
  }

  int get numGeometries => _geometries.length;
  int get length => numGeometries;
  Geometry geometryN(int i) => _geometries[i];
  Geometry operator [](int i) => geometryN(i);
}

class MultiSurface extends GeometryCollection {
  MultiSurface(Collection<Geometry> geometries) :super(geometries);
}

class MultiPolygon extends MultiSurface {
  MultiPolygon(Collection<Polygon> polygons) :super(polygons);
}

class Surface extends Geometry {

}

class MultiCurve extends GeometryCollection {
  MultiCurve(Collection<Geometry> geometries) :super(geometries);
}

class MultiLineString extends MultiCurve {
  MultiLineString(Collection<LineString> lineStrings) :super(lineStrings);
}


class MultiPoint extends GeometryCollection {
  MultiPoint(Collection<Point> points) :super(points);
}


class Polygon extends Surface {
  LinearRing _exteriorRing;
  List<LinearRing> _interiorRings = [];

  /**
   * Creates a polygon from an [exteriorRing] and an (optional)
   * list [interiorRings] of interior rings.
   */
  Polygon(LinearRing exteriorRing, [List<LinearRing> interiorRings]) {
    if (exteriorRing == null) throw new ArgumentError(
        "exteriorRing must not be null");
    _exteriorRing = exteriorRing;
    if (LinearRing != null) {
      interiorRings.remove(null);
      _interiorRings.addAll(interiorRings);
    }
  }

  LinearRing get exteriorRing => _exteriorRing;
  int get numInteriorRing => _interiorRings.length;
  LineString interiorRingN(int i) => _interiorRings[i];
}


class Point extends Geometry {

  num _x;
  num _y;

  int get dimension => 0;

  /**
   * Creates a point for coordinates ([x], [y]).
   *
   */
  Point(num x, num y) {
    assert(x != null && y != null);
    _x = x;
    _y = y;
  }

  /**
   * Creates a [Point] from data given by [other].
   *
   * [other] is either
   *   * another [Point] in which case a clone of [other] is created
   *   * a [List] of length 2 with two elements of type [num]
   *   * a [Map] with numeric properties `x` and `y`
   *
   * Throws [ArgumentError] if [other] is null or of an unsupported
   * type.
   */
  factory Point.from(other) {
    if (other is Point) return new Point(other.x, other.y);
    if (other is List) return new Point._fromList(other);
    if (other is Map) return new Point._fromMap(other);
    throw new ArgumentError("can't create a Point from $other");
  }

  factory Point._fromList(l) {
    if (l.length != 2)
      throw new ArgumentError("expected list of length 2, got ${l.length}");
    if (l[0] is! num || l[1] is! num)
      throw new ArgumentError("expected [number1, number2], got ${l}");
    return new Point(l[0], l[1]);
  }

  factory Point._fromMap(Map m) {
    if (!m.containsKey("x"))
       throw new ArgumentError("missing property 'x' in map $m");
    if (!m.containsKey("y"))
       throw new ArgumentError("missing property 'y' in map $m");
    if (m["x"] is! num)
       throw new ArgumentError("property 'x' is not a number");
    if (m["y"] is! num)
       throw new ArgumentError("property 'y' is not a number");
    return new Point(m["x"], m["y"]);
  }

  /**
   * Creates a point at origin (0,0).
   */
  Point.origin(): this(0,0);

  /// the x coordinate
  num get x => _x;
  /// the y coordinate
  num get y => _y;

  /**
   * A new point multiplied by [rhs].
   *
   * [rhs] is either
   *   * a [num]
   *   * another [Point]
   *
   */
  Point operator *(rhs) {
    if (rhs is num) return new Point(x * rhs, y * rhs);
    else if (rhs is Point) return new Point(x * rhs.x, y * rhs.y);
    else if (rhs is List) return this * new Point.from(rhs);
    else throw new ArgumentError("expected num or Point, got $rhs");
  }

  /**
   * A new point from which [rhs] is subtracted
   *
   * [rhs] is either
   *   * a [num]
   *   * another [Point]
   *
   */
  Point operator -(rhs) {
    if (rhs is num) return new Point(x - rhs, y - rhs);
    else if (rhs is Point) return new Point(x - rhs.x, y - rhs.y);
    else throw new ArgumentError("expected num or Point, got $rhs");
  }


  /// a new point whose x- and y-coordinates are rounded
  Point round([num decimalPlaces]) {
    decimalPlaces = ?decimalPlaces ? math.max(decimalPlaces, 0) : 0;
    decimalPlaces = decimalPlaces.toInt();
    if (decimalPlaces == 0) {
      return new Point(x.round(), y.round());
    }
    var n = pow(10, decimalPlaces);
    var x = (this.x * n).round() / n;
    var y = (this.y * n).round() / n;
    return new Point(x,y);
  }

  /// a new point whose x- and y-coordinates aree divided by [factor]
  Point divideBy(num factor) => new Point(x / factor, y / factor);
  Point operator /(factor) => divideBy(factor);

  /**
   * A new point from which [rhs] is added
   *
   * [rhs] is either
   *   * a [num]
   *   * another [Point]
   *   * a [List] with two elements x,y of type [num]
   *
   */
  Point operator +(rhs) {
    if (rhs is List) rhs = new Point.from(rhs);
    if (rhs is num) return new Point(x + rhs, y + rhs);
    else if (rhs is Point) return new Point(x + rhs.x, y + rhs.y);
    else throw new ArgumentError("expected num, Point, or List, got $rhs");
  }



  /**
   * Integer division
   *
   * [other] is either
   *    * a [num]: retuns a new point whose `x` and `y` is divided
   *      by [other]
   *    * a [Point]: return a new point whose `x` is divided by
   *      [:other.x:] and `y` is divided by [:other.y:]
   */
  Point operator ~/ (other) {
    if (other == null) throw new ArgumentError("other must not be null");
    else if (other is num) {
      return new Point(x ~/ other, y ~/ other);
    } else if (other is Point) {
      return new Point(x ~/ other.x, y ~/ other.y);
    } else {
      throw new ArgumentError("expected num or Point, can't evaluate ~/ with rhs $other");
    }
  }

  Point toInt() => new Point(x.toInt(), y.toInt());

  String toString() => "{Point: x=$x, y=$y}";

  bool operator ==(other) {
    if (other == null || other is! Point) return false;
    return x == other.x && y == other.y;
  }

  Point min(Point other) => new Point(math.min(x, other.x), math.min(y, other.y));
  Point max(Point other) => new Point(math.max(x, other.x), math.max(y, other.y));

  /// a new point with `x` translated by [dx] and `y` translated by [dy]
  Point translate(num dx, num dy) => this + [dx, dy];
  Point scale(num scalex, num scaley) => this * [scalex, scaley];
  Point flipY() => new Point(x, -y);
}

Geometry parseGeoJson(String geoJson) {
  var value = json.parse(geoJson);
  assert(value is Map);

  Point pos(coord) => new Point(coord[0], coord[1]);
  List<Point> poslist(l) => l.map(pos).toList();

  deserializePoint(Map gj) =>
      pos(gj["coordinates"]);

  deserializeMultiPoint(Map gj) =>
      new MultiPoint(poslist(gj["coordinates"]));

  deserializeLineString(Map gj) =>
      new LineString(poslist(gj["coordinates"]));

  deserializeMultiLineString(Map gj) =>
    new MultiLineString(
      gj["coordinates"]
      .map((ls) => new LineString(poslist(ls)))
      .toList()
    );

  polygonFromCoordinates(coords) {
    var rings = coords
    .map((l) => poslist(l))
    .map((poslist) => new LinearRing(poslist))
    .toList();
    var externalRing = rings[0];
    var internalRings = rings.length <= 1
        ? null
        : rings.getRange(1, rings.length -1);
    return new Polygon(externalRing, internalRings);
  }

  deserializePolygon(Map gj) =>
    polygonFromCoordinates(gj["coordinates"]);

  deserializeMultipolygon(Map gj) =>
      new MultiPolygon(
          gj["coordinates"]
          .map((coords) => polygonFromCoordinates(coords))
          .toList()
      );

  var deserialize;

  deserializeGeometryCollection(Map gj) =>
      new GeometryCollection(gj["geometries"]
        .map((o) => deserialize(o))
        .toList()
      );

  deserialize = (Map gj) {
    switch(gj["type"]) {
      case "Point":      return deserializePoint(gj);
      case "MultiPoint": return deserializeMultiPoint(gj);
      case "LineString": return deserializeLineString(gj);
      case "MultiLineString": return deserializeMultiLineString(gj);
      case "Polygon":    return deserializePolygon(gj);
      case "MultiPolygon": return deserializeMultipolygon(gj);
      case "GeometryCollection": return deserializeGeometryCollection(gj);
      default: throw new FormatException(
            "unknown GeoJson object type '${gj['type']}");
      //TODO: "Feature", or "FeatureCollection"
    }
  };

  return deserialize(value);
}

