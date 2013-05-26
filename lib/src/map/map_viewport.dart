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
  /// the type of event (either [ADDED], [REMOVED], or [MOVED])
  final int type;

  /// Creates an event of type [type] emitted by [map] for [layer]
  LayerEvent(this.map, this.layer, this.type);
}

/**
 * A MapViewport provides a view on a rectangular area of a map
 * plane in a stack of map planes on different zoom levels.
 * 
 * It also provides the functionality to change between map
 * planes (zoom in and zoom out) and to move the viewport
 * around on the current map plane (pan left, rigth, up, or down). 
 * 
 * A MapViewport manages a stack of map [Layer]s. 
 * 
 * A MapViewport is a [PropertyObservable]. It emits propery change
 * events for
 * * [: zoom :]  - emitted if the zoom level is changed
 * * [: center :]  - emitted if the center of the map viewport is changed
 */
class MapViewport extends Object with PropertyObservable{

  DivElement _root;

  /// the root DOM element of the map viewport
  Element get root => _root;

  //TODO: make configurable.
  final ProjectedCRS _crs = new EPSG3857();
  ProjectedCRS get crs => _crs;

  /**
   * Creates a map viewport.
   *
   * [container] is either an [Element] or a string consisting of
   * a CSS selector.
   */
  MapViewport(container) {
    _require(container != null,"container must not be null");
    if (container is String) {
      container = query(container);
      _require(container != null, "didn't find container with id '$container'");
    } else if (container is Element) {
      // OK
    } else {
      _require(false,"expected Element or String, got $container");
    }
    _root = new DivElement()
      ..classes.add("dartkart-map-viewport");
    container.children
      ..clear()
      ..add(_root);
    attachEventListeners();
    controlsPane = new ControlsPane();
  }

  void attachEventListeners() {
    //TODO: remind subscription; solve detach
    _root.onMouseWheel.listen(_onMouseWheel);
    new _DragController(this);
    new _DoubleClickController(this);
  }

  /// Transforms projected coordinates [p] to coordinates in the current map
  /// zoom plane
  Point2D mapToZoomPlane(Point2D p) {
    var zp = zoomPlaneSize;
    var w = _crs.projectedBounds.width;
    var h = _crs.projectedBounds.height;
    return p.flipY()
     .translate(dx: w/2, dy: h/2)
     .scale(sx: zp.x/w, sy: zp.y/h)
     .toInt();
  }

  /// Transforms coordinates [p] in the current map zoom plane to
  /// projected coordinates
  Point2D zoomPlaneToMap(Point2D p) {
    var zp = zoomPlaneSize;
    var w = _crs.projectedBounds.width;
    var h = _crs.projectedBounds.height;
    return p.scale(sx: w/zp.x, sy: h/zp.y)
        .translate(dx:-w/2, dy:-h/2)
        .flipY();
  }

  /// Transforms coordinates in the current map zoom plane to viewport
  /// coordinates
  Point2D zoomPlaneToViewport(Point2D p) {
   var centerOnZoomPlane = mapToZoomPlane(earthToMap(center));
   return ((viewportSize / 2) + (p - centerOnZoomPlane)).toInt();
  }

  /// viewport coordinates to coordinates in the current map zoom plane
  Point2D viewportToZoomPlane(Point2D p) {
    var centerOnZoomPlane = mapToZoomPlane(earthToMap(center));
    var delta = p - (viewportSize / 2);
    return (centerOnZoomPlane + delta).toInt();
  }

  /// Transforms geographic coordinates [ll] to projected coordinates
  Point2D earthToMap(LatLon ll) => _crs.project(ll);

  /// Transforms projected coordinates [p] to geographic coordinates
  LatLon mapToEarth(Point2D p) => _crs.unproject(p);

  /// the viewport size
  Dimension get viewportSize =>
      new Dimension(_root.client.width, _root.client.height);

  /// the size of the current map zoom plane
  Dimension get zoomPlaneSize {
    var dim = (1 << zoom) * 256;
    return new Dimension(dim, dim);
  }

  /// the top-left point in "page coordinates"
  Point2D get topLeftInPage {
    offset(Element e) {
      var p = new Point2D(e.offset.left, e.offset.top);
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
   *   * a [Point2D]
   *   * a [MouseEvent] - uses the coordinates (pageX, pageY)
   *
   *  The result are viewport coordinates for the map viewport where
   *    * (0,0) is the upper left corner of the map viewport
   *    * x runs to the right
   *    * y runs down
   */
  Point2D pageToViewport(v) {
    if (v is MouseEvent) {
      v = new Point2D(v.page.x, v.page.y);
    } else if (v is Point2D) {} // do nothing
    else throw new ArgumentError("expected MouseEvent or Point2D, got $v");
    return v - topLeftInPage;
  }

  /**
   * Renders the map.
   */
  void render() {
    _layers.forEach((l)=> l.render());
    _controlsPane.layout();
  }

  /* ----------------------- layer handling -------------------------- */
  final List<Layer> _layers = [];

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
  void addLayer(Layer layer) {
    _require(layer != null, "layer must not be null");
    if (hasLayer(layer)) return;
    _layers.add(layer);
    _root.children.add(layer.container);
    layer.attach(this);
    _updateLayerZIndex();
    render();
    _notifyLayerEvent(layer,LayerEvent.ADDED);
  }

  /**
   * Removes [layer] from the stack of layers of this map.
   *
   * Ignores [layer] if it is null or if it isn't attached to this map.
   */
  void removeLayer(Layer layer) {
    if (layer == null) return;
    if (!hasLayer(layer)) return;
    layer.detach();
    _root.children.remove(layer.container);
    _layers.remove(layer);
    _updateLayerZIndex();
    render();
    _notifyLayerEvent(layer,LayerEvent.REMOVED);
  }

  /// true, if [layer] is part of the layer stack of this map
  bool hasLayer(Layer layer) => _layers.contains(layer);

  /// an unmodifiable list of layers of this map. Empty, if
  /// no layes are defined.
  List<Layer> get layers => new UnmodifiableListView(_layers);

  /**
   * Moves the [layer] to the top.
   */
  void moveToTop(Layer layer) {
    if (!hasLayer(layer)) return;
    _layers.remove(layer);
    _layers.add(layer);
    _updateLayerZIndex();
    _notifyLayerEvent(layer,LayerEvent.MOVED);
  }

  /**
   * Moves the [layer] to the bottom.
   */
  void moveToBottom(Layer layer) {
    if (!hasLayer(layer)) return;
    _layers
      ..remove(layer)
      ..insert(0, layer);
    _updateLayerZIndex();
    _notifyLayerEvent(layer,LayerEvent.MOVED);
  }

  /**
   * Moves the [layer] to the position [index] in the
   * layer stack.
   */
  void moveTo(Layer layer, int index) {
    if (!hasLayer(layer)) return;
    index = math.max(index, 0);
    index = math.min(index, _layers.length);
    _layers
      ..remove(layer)
      ..insert(index,layer);
    _updateLayerZIndex();
    _notifyLayerEvent(layer,LayerEvent.MOVED);
  }

  final StreamController<LayerEvent> _layerEventsController =
      new StreamController<LayerEvent>();
  Stream<LayerEvent> _layerEventsStream;
  
  _notifyLayerEvent(layer, type) {
    if (!_layerEventsController.hasListener) return;
    if (_layerEventsController.isPaused) return;
    var event = new LayerEvent(this, layer, type);
    _layerEventsController.sink.add(event);
  }

  /**
   * Stream of layer change events.
   *
   * ## Example
   *
   *     map.onLayersChanged
   *       .where((LayerEvent e) => e.type == LayerEvent.ADDED))
   *       .listen((LayerEvent e) {
   *           print("layer added - num layers: ${map.layers.length}");
   *       });
   */
  Stream<LayerEvent> get onLayersChanged {
    if (_layerEventsStream == null) {
      _layerEventsStream = _layerEventsController.stream.asBroadcastStream();
    }
    return _layerEventsStream;
  }

  /* ----------------------- zooming       --------------------------- */
  int _zoom = 0;

  /// the current zoom level
  int get zoom => _zoom;

  /**
   * Set the zoom level [zoom].
   *
   * [zoom] >= 0 expected, otherwise throws an [ArgumentError].
   */
  void set zoom(int value) {
    _require(value >= 0, "zoom >= 0 expected, got $value");
    if (value == _zoom) return;
    _zoom = value;
    render();
    notify("zoom", _zoom, value);
  }

  /**
   * Zoom in by [delta] zoom levels.
   *
   * Throws [ArgumentError] if [delta] < 0. Fires a zoom change event.
   */
  void zoomIn([int delta=1]) {
    _require(delta >= 0, "delta >= 0 expected, got $delta");
    if (delta == 0) return;

    //TODO: check for max zoom level
    var oldZoom = _zoom;
    _zoom+= delta;
    render();
    notify("zoom", oldZoom, _zoom);
  }

  /**
   * Zoom out by [delta] zoom levels.
   *
   * Throws [ArgumentError] if [delta] < 0. Fires a zoom change event.
   */
  void zoomOut([int delta=1]) {
    if (delta < 0) throw new ArgumentError("delta >= 0 expected, got $delta");
    if (delta == 0) return;
    var oldZoom = _zoom;
    _zoom = math.max(0, _zoom - delta);
    render();
    notify("zoom", oldZoom, _zoom);
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
  void set center(LatLon value) {
    _require(value != null, "center must not be null");
    if (_center == value) return;
    var old = _center;
    _center = value;    
    render();
    notify("center", old, _center);
  }

  /* --------------------- panning ---------------------------------- */
  void pan(delta, {bool animate: false}) {
    if (animate) {
      new PanBehaviour(this).animate(new Point2D.from(delta));
    } else {
      delta = new Point2D.from(delta);
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
  void panNorth({int pixels:100, bool animate:false}) =>
      pan([0,-pixels], animate: animate);

  /// Pans the viewport num [pixels] to the south.
  /// Animates panning if [animate] is true.
  void panSouth({int pixels:100, bool animate:false}) =>
      pan([0,pixels], animate: animate);

  /// Pans the viewport num [pixels] to the west
  /// Animates panning if [animate] is true.
  void panWest({int pixels:100, bool animate:false}) =>
      pan([-pixels, 0], animate: animate);

  /// Pans the viewport num [pixels] to the east
  /// Animates panning if [animate] is true.
  void panEast({int pixels:100, bool animate:false}) =>
      pan([pixels, 0],animate: animate);

  /* ----------------------- controls pane ------------------------ */
  ControlsPane _controlsPane;

  /// the pane with the interactive map controls
  ControlsPane get controlsPane => _controlsPane;

  /// sets the [pane] for the interactive map controls
  void set controlsPane(ControlsPane pane) {
    if (pane == _controlsPane) return; // don't add twice
    if (_controlsPane != null) {
      _controlsPane.detach();
      _root.children.remove(_controlsPane.root);
    }
    _controlsPane = pane;
    if (_controlsPane != null) {
      _controlsPane
        ..attach(this)
        // render the controls pane on top of the map layers.
        // The z-index for the top most layer is 0.
        ..root.style.zIndex = "100";
      _root.children.add(_controlsPane.root);
    }
  }
}

class _DoubleClickController {
  final map;
  _DoubleClickController(this.map) {
    var stream = new MouseEventStream.from(map.root).stream;
    stream.where((p) => p.type == MouseEvent.DOUBLE_CLICK)
      .listen((p) => _onDoubleClick(p.event));
  }
  _onDoubleClick(evt) => map.zoomIn();
}

class _DragController {
  final map;
  Point2D _dragStart;
  Point2D _dragLast;
  Point2D _centerOnZoomPlane;

  _DragController(this.map) {
    var stream = new MouseEventStream.from(map.root).stream;
    stream.where((p) => p.isDragPrimitive).listen((p) {
      switch(p.type) {
        case MouseEvent.DRAG_START: _onDragStart(p.event); break;
        case MouseEvent.DRAG_END: _onDragEnd(p.event); break;
        case MouseEvent.DRAG: _onDrag(p.event); break;
      }
    });
  }

  _onDragStart(evt) {
    _dragStart = new Point2D(evt.screen.x, evt.screen.y);
    _dragLast = new Point2D.from(_dragStart);
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
    cur = new Point2D(evt.screen.x, evt.screen.y);
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

/**
 * `PanBehaviour` controls animated panning of a map viewport.
 */
class PanBehaviour {
  const double ACCELERATION = -2.0; // px / (100ms)²
  const double SPEED = 20.0;        // px / 100ms
  const int DELTA_T = 20;           // ms, duration of animation step

  /// the map viewport controlled by this behaviour
  final MapViewport viewport;
  
  /// Creates a new behaviour controlling [viewport].
  PanBehaviour(this.viewport);

  /**
   * Animate the panning of the map viewport by a vector given
   * by [panBy].
   */
  void animate(Point2D panBy) {
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
      var p = new Point2D(dx,dy).toInt();
      if (p != new Point2D.origin()) viewport.pan(p);
    }

    bounded(num v, num bound) => bound < 0
        ? math.max(v, bound)
        : math.min(v, bound);

    // pan long distance (fast) as much and possible, the complete
    // the future with the remaining pan distance
    Future<Point2D> panLongDistance(Point2D panBy) {
      var completer = new Completer<Point2D>();
      var pannedX = 0;
      var pannedY = 0;
      bool isLongDistance() =>
              (panBy.x - pannedX).abs() > 100
          || (panBy.y  - pannedY).abs() > 100;

      // animation step
      step(Timer timer){
        if (!isLongDistance()) {
          timer.cancel();
          var rest = new Point2D(panBy.x - pannedX, panBy.y - pannedY);
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
    panShortDistance(Point2D panBy) {
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
        if (v <= 0 || panBy == new Point2D(x,y)){
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