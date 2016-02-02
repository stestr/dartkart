/**
 * The library `dartkart.map` provides an implementation of a map viewport
 * and of a collection of map controls.
 */
library dartkart.map;

import "dart:html" hide Point, MouseEvent, Dimension;
import "dart:html" as html show MouseEvent;
import "dart:math" as math;
import "dart:svg" hide Point, Rect;
import "dart:async";
import "dart:collection";

import "layer.dart";
import "geometry.dart";
import "geo.dart";
import "core.dart";

part 'map/map_viewport.dart';
part "map/controls.dart";
part "map/mouse_events.dart";

_require(cond, [msg=""]) {
  if (!cond) throw new ArgumentError(msg);
}
