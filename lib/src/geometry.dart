library dartkart.geometry;
import "dart:math";
import "dart:math" as math;
import "dart:collection";
import "dart:async";
import "dart:json" as json;

part 'geometry/bounds.dart';
part "geometry/point2d.dart";
part "geometry/dimension.dart";

_require(cond,[msg=""]) {
  if (cond) return;
  throw new ArgumentError(msg);
}

