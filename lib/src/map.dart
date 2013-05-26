/**
 * The library `dartkart.map` provides an implementation of a map viewport
 * and of a collection of map controls.
 */
library dartkart.map;

import "dart:html" hide Point, Rect;
import "dart:html" as html show Rect;
import "dart:math" as math;
import "dart:svg" hide Point, Rect;
import "dart:async";
import "dart:collection";
import "package:meta/meta.dart";

import "layer.dart";
import "geometry.dart";
import "geo.dart";
import "core.dart";

part 'map/map_viewport.dart';
part "map/controls.dart";

_require(cond, [msg=""]) {
  if (!cond) throw new ArgumentError(msg);
}
