part of  dartkart.geometry;

class Point {

  num _x;
  num _y;

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

