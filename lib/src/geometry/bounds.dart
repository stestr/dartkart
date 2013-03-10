part of dartkart.geometry;

/**
 * Bounds represents a rectangular area on the screen in pixel coordinates
 * or a rectangular area in a rendered coordinate system.
 */
class Bounds {
  Point _min;
  Point _max;

  /**
   * Creates a new bounds given two corner points.
   *
   * [min] is the lower left, [max] the upper right point. Both are either
   * [Point]s or any other object accepted by [Point.from].
   *
   * Examples:
   *     var b1 = new Bounds(new Point(0,0), new Point(2,2));
   *     var b2 = new Bounds([0,0], [2,2]);
   *     var b2 = new Bounds({x: 0, y: 0}, {x:2, y: 2});
   */
  Bounds(min, max) {
    _min = new Point.from(min);
    _max = new Point.from(max);
  }

  Point get min => _min;
  Point get max => _max;

  /**
   * Creates a bounds from another value [other].
   *
   * [other] can be one of the following values:
   *   * a [Bounds]  -> replies a copy of [other]
   */
  factory Bounds.from(other) {
    if (other is Bounds) return new Bounds(other.min, other.max);
  }

  /**
   * Replies an extended version of this bounds which
   * includes the point [other].
   */
  Bounds extendTo(Point other) => new Bounds(min.min(other), max.max(other));

  Point get center => (min + max) / 2;
  Point get size => max - min;

  /**
   * Checks whether this bounds contains [other].
   *
   * [other] is either another [Bounds] or a [Point].
   *
   */
  bool contains(obj) {
    if (obj is Point) {
      return min.x <= obj.x && obj.x <= max.x
          && min.y <= obj.y && obj.y <= max.y;
    } else if (obj is Bounds) {
      return contains(obj.min) && contains(obj.max);
    } else {
      throw new ArgumentError("expected Point or Bounds, got $obj");
    }
  }

  bool intersects(Bounds other) =>
       (other.max.x >= min.x) && (other.min.x <= max.x)
    && (other.max.y >= min.y) && (other.min.y <= max.y);


  num get width => max.x - min.x;
  num get height => max.y - min.y;

  toString() => "{Bounds: min=$min, max=$max}";

}

