part of dartkart.geometry;

/**
 * A point in 2D cartesian space.
 */
class Point2D implements Comparable<Point2D>{
  /// the x-coordinate
  final num x;

  /// the y-coordinate
  final num y;

  /**
   * Creates a point for the [x] and [y] coordinate.
   */
  Point2D(this.x, this.y);

  /**
   * Creates a point from another object [other].
   *
   * ## Possible values for [other]
   *
   * * another [Point2D], in which case [other] is cloned
   * * a [List] with exactly two [num] values.
   *
   * ## Examples
   *
   *     var p1 = new Point2D.from([0,1]);
   *     var p2 = new Point2D.from(p1);
   */
  factory Point2D.from(other) {
    fromPoint(other) => new Point2D(other.x, other.y);
    fromList(other) {
      _require(other.length == 2, "expected list of length 2");
      _require(other.every((e) => e is num), "expected elements of type num only");
      return new Point2D(other[0], other[1]);
    }
    if (other is Point2D) return fromPoint(other);
    if (other is List) return fromList(other);
    _require(false, "expected Point2D or List, got $other");
  }

  /**
   * Creates a new point at position (0,0)
   */
  Point2D.origin() : this(0,0);

  int compareTo(Point2D other) {
    var c = x.compareTo(other.x);
    if (c != 0) return c;
    return y.compareTo(other.y);
  }

  bool operator==(other) => x == other.x && y == other.y;

  Point2D operator +(other) => new Point2D(x + other.x, y + other.y);
  Point2D operator -() => new Point2D(-x, -y);
  Point2D operator -(other) => this + (-other);
  Point2D operator *(num factor) => new Point2D(x * factor, y * factor);
  Point2D operator /(num divisor) => new Point2D(x / divisor, y / divisor);

  int get hashCode => x.hashCode * 31 + y.hashCode;

  /// returns a new point whose coordinates are converted to [int]
  Point2D toInt() => new Point2D(x.toInt(), y.toInt());

  /// returns a new point with the minimal coordinates of this and [other]
  Point2D min(other) => new Point2D(math.min(x, other.x), math.min(y, other.y));

  /// returns a new point with the maximal coordinates of this and [other]
  Point2D max(other) => new Point2D(math.max(x, other.x), math.max(y, other.y));

  /// returns a new point translate by [dx] in x direction and [dy] in
  /// y direction
  Point2D translate({num dx:0, num dy: 0}) => new Point2D(x + dx, y + dy);

  /// returns a new point scaled by [sx] in x direction and by [sy]
  /// in y direction
  Point2D scale({num sx:1, num sy:1}) => new Point2D(x* sx, y * sy);

  /// returns a new point for which the sign of the y-coordinates is inverted
  Point2D flipY() => scale(sy:-1);

  /**
   * returns a new point whose coordinates are truncated to
   * [afterDecimalPoint] digits after the decimal point.
   */
  Point2D truncate([num afterDecimalPoint=0]) {
    var d = math.pow(10, afterDecimalPoint);
    var x= (this.x * d).truncateToDouble() / d;
    var y= (this.y * d).truncateToDouble() / d;
    return new Point2D(x,y);
  }

  String toString() => "{Point2D: x=$x, y=$y}";

}