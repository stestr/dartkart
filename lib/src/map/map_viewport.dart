part of dartkart.map;

/**
 * A layer event emitted by a [MapViewport]
 */
class LayerEvent {
  /// layer has been added
  static const ADDED = 0;
  /// layer has been removed
  static const REMOVED = 1;
  /// layer has been moved
  static const MOVED = 2;

  /// the map viewport emitting the event
  final MapViewport map;
  /// the layer
  final Layer layer;
  /// the type of event (either [ADDED], [REMOVED], or [MOVED]
  final type;

  /// Creates an event of type [type] emitted by [map] for [layer]
  const LayerEvent(this.map, this.layer, this.type);
  const LayerEvent.added(map, layer): this(map, layer, ADDED);
  const LayerEvent.removed(map, layer):this(map, layer, REMOVED);
  const LayerEvent.moved(map, layer): this(map, layer, MOVED);
}

class MapViewport {

  DivElement _root;

  /// the root DOM element of the map viewport
  Element get root => _root;

  //TODO: make configurable.
  final ProjectedCRS _crs = new EPSG3857();
  ProjectedCRS get crs => _crs;

  /**
   * Creates a map.
   *
   * [container] is either an [Element] or a string with with
   * a CSS selector.
   *
   */
  MapViewport(container) {
    if (container == null) {
      throw new ArgumentError("container must not be null");
    }
    if (container is String) {
      container = query(container);
      if (container == null) {
        throw new ArgumentError("didn't find container with id '$container'");
      }
    } else if (container is Element) {
      // OK
    } else {
      throw new ArgumentError("expected an Element or a DOM id as String, "
          "got $container");
    }
    _root = new DivElement();
    _root.classes.add("dartkart-map-viewport");
    container.children.clear();
    container.children.add(_root);
    attachEventListeners();
    controlsPane = new ControlsPane();
  }

  attachEventListeners() {
    //TODO: remind subscription; solve detach
    _root.onMouseWheel.listen(_onMouseWheel);
    new _DragController(this);
    new _DoubleClickController(this);
  }

  /// Transforms projected coordinates [p] to coordinates in the current map
  /// zoom plane
  Point mapToZoomPlane(Point p) {
    var zp = zoomPlaneSize;
    var w = _crs.projectedBounds.width;
    var h = _crs.projectedBounds.height;
    return p.flipY()
     .translate(w/2, h/2)
     .scale(zp.x / w, zp.y / h)
     .toInt();
  }

  /// Transforms coordinates [p] in the current map zoom plane to
  /// projected coordinates
  Point zoomPlaneToMap(Point p) {
    var zp = zoomPlaneSize;
    var w = _crs.projectedBounds.width;
    var h = _crs.projectedBounds.height;
    return p.scale(w/ zp.x, h/ zp.y)
        .translate(-w/2, -h/2)
        .flipY();
  }

  /// Transforms coordinates in the current map zoom plane to viewport
  /// coordinates
  Point zoomPlaneToViewport(Point p) {
   var centerOnZoomPlane = mapToZoomPlane(earthToMap(center));
   return ((viewportSize / 2) + (p - centerOnZoomPlane)).toInt();
  }

  /// viewport coordinates to coordinates in the current map zoom plane
  Point viewportToZoomPlane(Point p) {
    var centerOnZoomPlane = mapToZoomPlane(earthToMap(center));
    var delta = p - (viewportSize / 2);
    return (centerOnZoomPlane + delta).toInt();
  }

  /// Transforms geographic coordinates [ll] to projected coordinates
  Point earthToMap(LatLon ll) => _crs.project(ll);

  /// Transforms projected coordinates [p] to geographic coordinates
  LatLon mapToEarth(Point p) => _crs.unproject(p);

  /// the viewport size
  Point get viewportSize =>
      new Point(_root.client.width, _root.client.height);

  /// the size of the current map zoom plane
  Point get zoomPlaneSize {
    var dim = (1 << zoom) * 256;
    return new Point(dim, dim);
  }

  /// the top-left point in "page coordinates"
  Point get topLeftInPage {
    offset(Element e) {
      var p = new Point(e.offset.left, e.offset.top);
      return e.parent == null ? p : p + offset(e.parent);
    }
    return offset(_root);
  }

  /**
   * The bounding box of the viewport in which we are currently rending
   * part of the map.
   *
   * The screen bounding box depends on the current zoom level ant the
   * current map center. In most cases, in partiuclar on zoom levels > 2,
   * it is equal to the extend of the map viewport. In lower zoom levels,
   * where the zoom plane is smaller than the map viewport, or if the
   * center is moved very far east, west, north, or south, it only covers
   * part of the viewport.
   *
   */
  Bounds get screenBoundingBox {
    var vpSize = viewportSize;
    var vpCenter = (viewportSize / 2).toInt();
    var zpSize = zoomPlaneSize;
    var zpCenter = mapToZoomPlane(earthToMap(center));
    var zp = zoomPlaneSize;
    var x = math.max(0, vpCenter.x - zpCenter.x);
    var y = math.max(0, vpCenter.y - zpCenter.y);
    var width = math.min(vpSize.x, vpCenter.x  + (zpSize.x - zpCenter.x));
    var height = math.min(vpSize.y, vpCenter.y  + (zpSize.y - zpCenter.y));
    return new Bounds([x,y], [x+width, y+height]);
  }

  /**
   * Transforms page coordinates to viewport coordinates.
   *
   * [v] is either
   *   * a [Point]
   *   * a [MouseEvent] - uses the coordinates (pageX, pageY)
   *
   *  The result are viewport coordinates for the map viewport where
   *    * (0,0) is the upper left corner of the map viewport
   *    * x runs to the right
   *    * y runs down
   */
  Point pageToViewport(v) {
    if (v is MouseEvent) {
      v = new Point(v.page.x, v.page.y);
    } else if (v is Point) {} // do nothing
    else throw new ArgumentError("expected MouseEvent or Point, got $v");
    return v - topLeftInPage;
  }

  /**
   * Renders the map.
   */
  render() {
    _layers.forEach((l)=> l.render());
    _controlsPane.layout();
  }

  /* ----------------------- layer handling -------------------------- */
  final List<Layer> _layers = [];
  final StreamController<LayerEvent> _layerEvents =
      new StreamController<LayerEvent>.broadcast();

  /// update the z-indexes of the layer. Reflects the ordering in
  /// the layer stack. The layer with the highest index is renderer
  /// on top, the layer with index 0 is rendered at the bottom.
  _updateLayerZIndex() {
    var reversed = _layers.reversed.toList();
    for (int i=0; i<layers.length; i++) {
      reversed[i].container.style.zIndex = (i * -100).toString();
    }
  }

  /**
   * Adds a [layer] to the map.
   *
   * [layer] is appended to the list of layers of this map. It therefore
   * has the highest layer index and becomes rendered on top of the layer
   * stack of this map.
   *
   * Throws [ArgumentError] if [layer] is null. [layer] is ignored if it
   * is already attached to this map.
   *
   * ##Example
   *    var source= "http://a.tile.openstreetmap.org/{z}/{x}/{y}.png";
   *    map.addLayer(new OsmLayer(tileSource: source));
   */
  addLayer(Layer layer) {
    if (layer == null) throw new ArgumentError("layer must not be null");
    if (hasLayer(layer)) return;
    _layers.add(layer);
    _root.children.add(layer.container);
    layer.attach(this);
    _updateLayerZIndex();
    render();
    _layerEvents.add(new LayerEvent.added(this, layer));
  }

  /**
   * Removes [layer] from the stack of layers of this map.
   *
   * Ignores [layer] if it is null or if it isn't attached to this map.
   */
  removeLayer(Layer layer) {
    if (layer == null) return;
    if (!hasLayer(layer)) return;
    layer.detach();
    _root.children.remove(layer.container);
    _layers.remove(layer);
    _updateLayerZIndex();
    render();
    _layerEvents.add(new LayerEvent.removed(this, layer));
  }

  /// true, if [layer] is part of the layer stack of this map
  bool hasLayer(Layer layer) => _layers.contains(layer);

  /// an unmodifiable list of layers of this map. Empty, if
  /// no layes are defined.
  List<Layer> get layers => new UnmodifiableListView(_layers);

  /**
   * Moves the [layer] to the top.
   */
  moveToTop(Layer layer) {
    if (!hasLayer(layer)) return;
    _layers.remove(layer);
    _layers.add(layer);
    _updateLayerZIndex();
    _layerEvents.add(new LayerEvent.moved(this, layer));
  }

  /**
   * Moves the [layer] to the bottom.
   */
  moveToBottom(Layer layer) {
    if (!hasLayer(layer)) return;
    _layers.remove(layer);
    _layers.insertRange(0, 1, layer);
    _updateLayerZIndex();
    _layerEvents.add(new LayerEvent.moved(this, layer));
  }

  /**
   * Moves the [layer] to the position [index] in the
   * layer stack.
   */
  moveTo(Layer layer, int index) {
    if (!hasLayer(layer)) return;
    index = math.max(index, 0);
    index = math.min(index, _layers.length);
    _layers.remove(layer);
    _layers.insertRange(index, 1, layer);
    _updateLayerZIndex();
    _layerEvents.add(new LayerEvent.moved(this, layer));
  }

  /**
   * Stream of layer change events.
   *
   * ## Example
   *
   *   map.onLayersChanged
   *     .where((LayerEvent e) => e.type == LayerEvent.ADDED))
   *     .listen((LayerEvent e) {
   *         print("layer added - cur num layers: ${map.layers.length}");
   *      });
   */
  Stream<LayerEvent> get onLayersChanged => _layerEvents.stream;

  /* ----------------------- zooming       --------------------------- */
  int _zoom = 0;

  /// the current zoom level
  int get zoom => _zoom;

  /**
   * Set the zoom level [zoom].
   *
   * [zoom] >= 0 expected, otherwise throws an [ArgumentError].
   */
  set zoom(int value) {
    if (value < 0) throw new ArgumentError("zoom >= 0 expected, got $value");
    if (value == _zoom) return;
    var event = new PropertyChangeEvent(this,"zoom", _zoom, value);
    _zoom = value;
    render();
    _events.sink.add(event);
  }

  /**
   * Zoom in by [delta] zoom levels.
   *
   * Throws [ArgumentError] if [delta] < 0. Fires a zoom change event.
   */
  zoomIn([int delta=1]) {
    if (delta < 0) throw new ArgumentError("delta >= 0 expected, got $delta");
    if (delta == 0) return;

    //TODO: check for max zoom level
    var oldZoom = _zoom;
    _zoom+= delta;
    render();
    var event = new PropertyChangeEvent(this,"zoom", oldZoom, _zoom);
    _events.sink.add(event);
  }

  /**
   * Zoom out by [delta] zoom levels.
   *
   * Throws [ArgumentError] if [delta] < 0. Fires a zoom change event.
   */
  zoomOut([int delta=1]) {
    if (delta < 0) throw new ArgumentError("delta >= 0 expected, got $delta");
    if (delta == 0) return;
    var oldZoom = _zoom;
    _zoom = math.max(0, _zoom - delta);
    render();
    var event = new PropertyChangeEvent(this,"zoom", oldZoom, _zoom);
    _events.sink.add(event);
  }

  /* ----------------------- event handlers --------------------------- */
  _onMouseWheel(WheelEvent evt) {
    // sign of deltaY is reversed in firefox
    if (evt.deltaY < 0) {
      var zoom = isFirefox ? zoomIn : zoomOut;
      zoom();
    } else if (evt.deltaY > 0) {
      var zoom = isFirefox ? zoomOut : zoomIn;
      zoom();
    }
  }

  /* --------------------- map center ---------------------------------- */
  LatLon _center = new LatLon.origin();

  /// the current map center in geographic coordinates
  LatLon get center => _center;

  /**
   * Sets the current map [center].
   *
   * [center] must not be null. Broadcasts a [PropertyChangeEvent] if
   * the center is changed, see [onCenterChanged].
   */
  set center(LatLon value) {
    if (value == null) throw new ArgumentError("center must not be null");
    if (_center == value) return;
    var old = _center;
    _center = value;
    render();
    _events.sink.add(new PropertyChangeEvent(this,"center", old, _center));
  }

  /* --------------------- panning ---------------------------------- */
  pan(delta, {bool animate: false}) {
    if (animate) {
      new PanBehaviour(this).animate(new Point.from(delta));
    } else {
      delta = new Point.from(delta);
      var p = mapToZoomPlane(earthToMap(center));
      p = p + delta;
      if (p.x <= 0 || p.y <= 0) return;
      var size = zoomPlaneSize;
      if (p.x >= size.x || p.y >= size.y) return;
      var c = zoomPlaneToMap(p);
      if (!crs.projectedBounds.contains(c)) return;
      center = mapToEarth(c);
    }
  }

  /// Pans the viewport num [pixels] to the north.
  /// Animates panning if [animate] is true.
  panNorth({int pixels:100, bool animate:false}) =>
      pan([0,-pixels], animate: animate);

  /// Pans the viewport num [pixels] to the south.
  /// Animates panning if [animate] is true.
  panSouth({int pixels:100, bool animate:false}) =>
      pan([0,pixels], animate: animate);

  /// Pans the viewport num [pixels] to the west
  /// Animates panning if [animate] is true.
  panWest({int pixels:100, bool animate:false}) =>
      pan([-pixels, 0], animate: animate);

  /// Pans the viewport num [pixels] to the east
  /// Animates panning if [animate] is true.
  panEast({int pixels:100, bool animate:false}) =>
      pan([pixels, 0],animate: animate);

  /* ----------------------- controls pane ------------------------ */
  ControlsPane _controlsPane;

  /// the pane with the interactive map controls
  ControlsPane get controlsPane => _controlsPane;

  /// sets the [pane] for the interactive map controls
  set controlsPane(ControlsPane pane) {
    if (pane == _controlsPane) return; // don't add twice
    if (_controlsPane != null) {
      _controlsPane.detach();
      _root.children.remove(_controlsPane.root);
    }
    _controlsPane = pane;
    if (_controlsPane != null) {
      _controlsPane.attach(this);
      // render the controls pane on top of the map layers.
      // The z-index for the top most layer is 0.
      _controlsPane.root.style.zIndex = "100";
      _root.children.add(_controlsPane.root);
    }
  }

  /* ----------------------- controls pane ------------------------ */
  StreamController _events = new StreamController.broadcast();
  Stream _zoomEvents;
  Stream _centerEvents;
  /**
   * The streams of zoom change events.
   *
   * Listen on this stream to get notified about changes of the zoom
   * level.
   *
   * Example:
   *    map.onZoomChanged.listen((e) {
   *       print("zoom changed: old=${e.oldValue}, new=${e.newValue}");
   *    });
   */
  Stream<PropertyChangeEvent> get onZoomChanged {
    if (_zoomEvents == null) {
      _zoomEvents = _events.stream.where((e) => e.name == "zoom");
    }
    return _zoomEvents;
  }

  /**
   * The streams of center change events.
   *
   * Listen on this stream to get notified when the map center is
   * changed.
   *
   * Example:
   *    // oldValue and newValue are LonLats
   *    map.onCenterChanged.listen((e) {
   *       print("zoom changed: old=${e.oldValue}, new=${e.newValue}");
   *    });
   */
  Stream<PropertyChangeEvent> get onCenterChanged {
    if (_centerEvents == null) {
      _centerEvents = _events.stream.where((e) => e.name == "center");
    }
    return _centerEvents;
  }
}

class _DoubleClickController {
  final map;
  _DoubleClickController(this.map) {
    var stream = new MouseGestureStream.from(map.root).stream;
    stream.where((p) => p.type == MouseGesturePrimitive.DOUBLE_CLICK)
      .listen((p) => _onDoubleClick(p.event));
  }
  _onDoubleClick(evt) => map.zoomIn();
}

class _DragController {
  final map;
  Point _dragStart;
  Point _dragLast;
  Point _centerOnZoomPlane;

  _DragController(this.map) {
    var stream = new MouseGestureStream.from(map.root).stream;
    stream.where((p) => p.isDragPrimitive).listen((p) {
      switch(p.type) {
        case MouseGesturePrimitive.DRAG_START: _onDragStart(p.event); break;
        case MouseGesturePrimitive.DRAG_END: _onDragEnd(p.event); break;
        case MouseGesturePrimitive.DRAG: _onDrag(p.event); break;
      }
    });
  }

  _onDragStart(evt) {
    _dragStart = new Point(evt.screen.x, evt.screen.y);
    _dragLast = new Point.from(_dragStart);
    _centerOnZoomPlane = map.mapToZoomPlane(map.earthToMap(map.center));
    evt.target.style.cursor = "move";
  }

  _onDragEnd(evt) {
    _dragStart = null;
    evt.target.style.cursor = "default";
  }

  _onDrag(evt) {
    assert(_dragStart != null);
    var cur;
    cur = new Point(evt.screen.x, evt.screen.y);
    // |cur - last| < 5
    var dx = cur.x - _dragLast.x;
    var dy = cur.y - _dragLast.y;
    if (dx*dx  + dy*dy <= 25) return;

    var c = _centerOnZoomPlane + (_dragStart - cur);
    c = map.zoomPlaneToMap(c);
    // don't drag if inverse projection of new center isn't
    // possible
    if (! map.crs.projectedBounds.contains(c)) return;
    map.center = map.mapToEarth(c);
    map.render();
  }
}

class MouseGesturePrimitive {
  static const int CLICK = 0;
  static const int DOUBLE_CLICK = 1;
  static const int DRAG_START = 2;
  static const int DRAG = 3;
  static const int DRAG_END = 4;
  static const int HOVER = 5;

  final int type;
  final MouseEvent event;
  MouseGesturePrimitive(this.type, this.event);
  MouseGesturePrimitive.click(event) : this(CLICK, event);
  MouseGesturePrimitive.doubleClick(event) : this(DOUBLE_CLICK, event);
  MouseGesturePrimitive.drag(event) : this(DRAG, event);
  MouseGesturePrimitive.hover(event) : this(HOVER, event);
  MouseGesturePrimitive.dragStart(event) : this(DRAG_START, event);
  MouseGesturePrimitive.dragEnd(event) : this(DRAG_END, event);

  String get _typeAsString {
    switch(type) {
      case CLICK: return "CLICK";
      case DOUBLE_CLICK: return "DOUBLE_CLICK";
      case DRAG: return "DRAG";
      case DRAG_START: return "DRAG_START";
      case DRAG_END: return "DRAG_END";
      case HOVER: return "HOVER";
    }
  }

  bool get isDragPrimitive => type == DRAG_START || type == DRAG ||
      type == DRAG_END;

  toString() => "{MouseGesturePrimitive: type=${_typeAsString}, x=${event.offset.x},"
     "y=${event.offset.y}";
}

class MouseGestureStream {
  var _controler = new StreamController.broadcast();
  var _subscriptions = [];

  var _lastMouseDownPos = null;
  var _lastMouseDownTimestamp = 0;
  var _mouseDown = false;
  var _isDragging = false;

  MouseGestureStream();
  MouseGestureStream.from(Element source) {
    attach(source);
  }

  var deferredEvent = null;

  _fireDeferred() {
    if (deferredEvent != null) {
      var e = deferredEvent;
      deferredEvent = null;
      _controler.sink.add(new MouseGesturePrimitive.click(e));
    }
  }

  _rawMouseClick(evt) {
    if (deferredEvent == null) {
      var ts = new DateTime.now().millisecondsSinceEpoch;
      if (ts - _lastMouseDownTimestamp > 150) {
        // a click generated at the end of a drag sequence
        //      mouse down, mouse move, ..., mouse move, mouse up, click
        // Ignore it.
        return;
      }
      deferredEvent = evt;
      new Timer(const Duration(milliseconds: 200), () => _fireDeferred());
    } else {
      deferredEvent = null;
      _controler.sink.add(new MouseGesturePrimitive.doubleClick(evt));
    }
  }

  _rawMouseMove(evt){
    if (_mouseDown) {
       if (!_isDragging) {
         _controler.sink.add(new MouseGesturePrimitive.dragStart(evt));
       }
      _isDragging = true;
    }
    if (_isDragging) {
      _controler.sink.add(new MouseGesturePrimitive.drag(evt));
    } else {
      _controler.sink.add(new MouseGesturePrimitive.hover(evt));
    }
  }

  _rawMouseDown(MouseEvent evt) {
    if (evt.button != 0 /* left */) return;
    evt.preventDefault();
    evt.stopPropagation();
    _mouseDown = true;
    _lastMouseDownTimestamp = new DateTime.now().millisecondsSinceEpoch;
    _lastMouseDownPos = new Point(evt.offset.x, evt.offset.y);
  }

  _rawMouseUp(MouseEvent evt) {
    if (evt.button != 0 /* left */) return;
    evt.preventDefault();
    evt.stopPropagation();
    if (_isDragging) {
      _controler.sink.add(new MouseGesturePrimitive.dragEnd(evt));
    }
    _mouseDown = false;
    _isDragging = false;
  }

  get stream => _controler.stream;

  detach() => _subscriptions.forEach((s) => s.cancel());

  attach(Element source) {
    _subscriptions.add(source.onClick.listen(_rawMouseClick));
    _subscriptions.add(source.onMouseDown.listen(_rawMouseDown));
    _subscriptions.add(source.onMouseUp.listen(_rawMouseUp));
    _subscriptions.add(source.onMouseMove.listen(_rawMouseMove));
  }
}

class PanBehaviour {
  const double ACCELERATION = -2.0; // px / (100ms)²
  const double SPEED = 20.0;        // px / 100ms
  const int DELTA_T = 20;           // ms, duration of animation step

  final MapViewport viewport;
  PanBehaviour(this.viewport);

  animate(Point panBy) {
    var dist = math.sqrt(math.pow(panBy.x,2) + math.pow(panBy.y,2));
    var theta = math.asin(panBy.y / dist);
    if (panBy.x <= 0) {
      theta = math.PI - theta;
    }

    var fx = math.cos(theta);
    //y-axis is inverted, therefore not
    //  -math.sin(theta)
    var fy = math.sin(theta);

    now() => new DateTime.now().millisecondsSinceEpoch;

    pan(dx,dy) {
      var p = new Point(dx,dy).toInt();
      if (p != new Point.origin()) viewport.pan(p);
    }

    bounded(num v, num bound) => bound < 0
        ? math.max(v, bound)
        : math.min(v, bound);

    // pan long distance (fast) as much and possible, the complete
    // the future with the remaining pan distance
    Future<Point> panLongDistance(Point panBy) {
      var completer = new Completer<Point>();
      var pannedX = 0;
      var pannedY = 0;
      bool isLongDistance() =>
              (panBy.x - pannedX).abs() > 100
          || (panBy.y  - pannedY).abs() > 100;

      // animation step
      step(Timer timer){
        if (!isLongDistance()) {
          timer.cancel();
          var rest = new Point(panBy.x - pannedX, panBy.y - pannedY);
          completer.complete(rest);
        } else {
          var dx = bounded(40 * fx, panBy.x).toInt();
          var dy = bounded(40 * fy, panBy.y).toInt();
          pannedX += dx;
          pannedY += dy;
          pan(dx, dy);
        }
      }
      new Timer.periodic(new Duration(milliseconds: DELTA_T), step);
      return completer.future;
    }

    // pan a short distance, deaccelerate and make sure the final
    // point is reached
    panShortDistance(Point panBy) {
      panBy = panBy.toInt();
      var lastX = 0;
      var lastY = 0;
      var initialTime = now();

      // animation step
      step(Timer timer) {
        // scale time by 100 for kinetics calcuations
        var t  = (now() - initialTime) / 100;
        var p = ACCELERATION * math.pow(t,2) / 2 + SPEED * t;
        var x = bounded(p * fx, panBy.x).toInt();
        var y = bounded(p * fy, panBy.y).toInt();
        var v = ACCELERATION * t + SPEED;
        if (v <= 0 || panBy == new Point(x,y)){
          // last step - pan to the end point
          x = panBy.x;
          y = panBy.y;
          timer.cancel();
        }
        var dx = x - lastX;
        var dy = y - lastY;
        lastX = x;
        lastY = y;

        pan(dx, dy);
      }
      new Timer.periodic(new Duration(milliseconds: DELTA_T), step);
    }

    panLongDistance(panBy).then((rest) {
      panShortDistance(rest);
    });
  }
}