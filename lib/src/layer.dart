/**
 * The library `dartkart.layer` provides various types of layers which
 * can be added to a [MapViewport].
 *
 */
library dartkart.layer;

import "dart:html" hide Point, Dimension;
import "dart:math" as math;
import "dart:collection";

import 'map.dart';
import 'core.dart';
import 'geometry.dart';
import "geo.dart";

part 'layer/base.dart';
part 'layer/tile_layer.dart';
//part 'layer/simplefeature_layer.dart';

_require(cond, [msg=""]) {
  if (!cond) throw new ArgumentError(msg);
}