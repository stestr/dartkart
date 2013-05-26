part of dartkart.geometry;

/**
 * Bounds represents a rectangular area on the screen in pixel coordinates
 * or a rectangular area in a rendered coordinate system.
 */
class Bounds {
  Point2D _min;
  Point2D _max;

  /**
   * Creates a new bounds given two corner Point2Ds.
   *
   * [min] is the lower left, [max] the upper right Point2D. Both are either
   * [Point2D]s or any other object accepted by [Point2D.from].
   *
   * Examples:
   *     var b1 = new Bounds(new Point2D(0,0), new Point2D(2,2));
   *     var b2 = new Bounds([0,0], [2,2]);
   */
  Bounds(min, max) {
    _min = new Point2D.from(min);
    _max = new Point2D.from(max);
  }

  /// the lower left point
  Point2D get min => _min;

  /// the upper right bounds
  Point2D get max => _max;

  /// the lower left point, see also [min]
  Point2D get lowerLeft => _min;
  /// the upper left corner point
  Point2D get upperLeft => new Point2D(_min.x, min.y + height);
  /// the upper right corner point
  Point2D get upperRight => _max;
  /// the lower right corner point
  Point2D get lowerRight => new Point2D(_min.x + width, min.y);

  /**
   * Creates a bounds from another value [other].
   *
   * [other] can be one of the following values:
   *
   * * a [Bounds]  -> replies a copy of [other]
   */
  factory Bounds.from(other) {
    if (other is Bounds) return new Bounds(other.min, other.max);
  }

  /**
   * Replies an extended version of this bounds which
   * includes [other].
   */
  Bounds extendTo(Point2D other) => new Bounds(min.min(other), max.max(other));

  /// the center point of this bounds object
  Point2D get center => (min + max).scale(sx:0.5, sy:0.5);

  Dimension get size => new Dimension(width, height);

  /**
   * Checks whether this bounds contains [other].
   *
   * [other] is either another [Bounds] or a [Point2D].
   *
   */
  bool contains(other) {
    if (other is Point2D) {
      return min.x <= other.x && other.x <= max.x
          && min.y <= other.y && other.y <= max.y;
    } else if (other is Bounds) {
      return contains(other.min) && contains(other.max);
    } else {
      throw new ArgumentError("expected Point2D or Bounds, got $other");
    }
  }

  /// returns true, if [other] intersects with this bounds
  bool intersects(Bounds other) =>
       (other.max.x >= min.x) && (other.min.x <= max.x)
    && (other.max.y >= min.y) && (other.min.y <= max.y);

  /// the width of the bounds
  num get width => max.x - min.x;
  /// the height of the bounds
  num get height => max.y - min.y;

  String toString() => "{Bounds: min=$min, max=$max}";
}

