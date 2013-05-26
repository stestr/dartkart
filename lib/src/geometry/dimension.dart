part of dartkart.geometry;

/**
 * The dimension of a rectangular area given by a width and a height.
 */
class Dimension {
  /// the width
  final num width;
  /// the height
  final num height;

  /**
   * Creates a dimension object with [width] and [height].
   *
   * Throws [ArgumentError] if either [width] or [height] is
   * negative.
   */
  Dimension(this.width, this.height) {
    _require(width >=0, "width must be positive");
    _require(height >=0, "height must be positive");
  }

  bool operator ==(other) => width == other.width && height == other.height;
  @override int get hashCode => width.hashCode * 31 + height.hashCode;
  @override String toString() => "{Dimension: width=$width, height=$height}";
}