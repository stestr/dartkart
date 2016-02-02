/**
 * The library `dartkart.geometry` provides classes for basic geometric
 * concepts like a 2-dimensional point, a dimension, or a boundary
 * box.
 */
library dartkart.geometry;
import "dart:math";
import "dart:math" as math;
import "dart:collection";
import "dart:async";
import "dart:convert";

part 'geometry/bounds.dart';
part "geometry/point2d.dart";
part "geometry/dimension.dart";

_require(cond,[msg=""]) {
  if (cond) return;
  throw new ArgumentError(msg);
}

