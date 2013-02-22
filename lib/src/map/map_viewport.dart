part of dartkart.map;

class MapViewport {

  DivElement _container;

  get container => _container;

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
    if (container is String) container = query(container);
    _container = container;
    attachEventListeners();
    controlsPane = new ControlsPane();
  }

  attachEventListeners() {
    //TODO: remind subscription; solve detach
    _container.onMouseWheel.listen(_onMouseWheel);
    new DragController(this);
    new DoubleClickController(this);
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

  /// Transforms geographic coordinates [ll] to projrected coordinates
  Point earthToMap(LatLon ll) => _crs.project(ll);

  /// Transforms projected coordinates [p] to geographic coordinates
  LatLon mapToEarth(Point p) => _crs.unproject(p);

  /// the viewport size
  Point get viewportSize =>
      new Point(_container.clientWidth, _container.clientHeight);

  /// the size of the current map zoom plane
  Point get zoomPlaneSize {
    var dim = (1 << zoom) * 256;
    return new Point(dim, dim);
  }

  /// the top-left point in "page coordinates"
  Point get topLeftInPage {
    offset(Element e) {
      var p = new Point(e.offsetLeft, e.offsetTop);
      return e.parent == null ? p : p + offset(e.parent);
    }
    return offset(_container);
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
      v = new Point(v.pageX, v.pageY);
    } else if (v is Point) {} // do nothing
    else throw new ArgumentError("expected MouseEvent or Point, got $v");
    return v - topLeftInPage;
  }

  /**
   * Renders the map.  
   */
  render() {
    _layers.forEach((l)=> l.render()); 
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
  addLayer(Layer layer) {
    if (layer == null) throw new ArgumentError("layer must not be null");
    if (hasLayer(layer)) return;
    _layers.add(layer);   
    _container.children.add(layer.container);
    layer.attach(this);
    _updateLayerZIndex();
    render();
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
    _container.children.remove(layer.container);
    _layers.remove(layer);
    _updateLayerZIndex();
    render();
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
  }

  /**
   * Moves the [layer] to the bottom. 
   */
  moveToBottom(Layer layer) {
    if (!hasLayer(layer)) return;
    _layers.remove(layer);
    _layers.insertRange(0, 1, layer);
    _updateLayerZIndex();
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
  set zoom(int value) {
    if (value < 0) throw new ArgumentError("zoom >= 0 expected, got $value");
    if (value == _zoom) return;
    var event = new PropertyChangeEvent("zoom", _zoom, value);
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
    var event = new PropertyChangeEvent("zoom", oldZoom, _zoom);
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
    var event = new PropertyChangeEvent("zoom", oldZoom, _zoom);
    _events.sink.add(event);
  }

  /* ----------------------- event handlers --------------------------- */
  _onMouseWheel(WheelEvent evt) {
    if (evt.deltaY < 0) {
      zoomOut();
    } else if (evt.deltaY > 0) {
      zoomIn();
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
    _events.sink.add(new PropertyChangeEvent("center", old, _center));
  }

  /* --------------------- panning ---------------------------------- */
  //TODO: panning with animation

  _pan(delta) {
    delta = new Point.from(delta);
    var p = mapToZoomPlane(earthToMap(center));
    p = p + delta;
    if (p.x <= 0 || p.y <= 0) return;
    var size = zoomPlaneSize;
    if (p.x >= size.x || p.y >= size.y) return;
    var c = mapToEarth(zoomPlaneToMap(p));
    center = c;
  }

  /// Pans the viewport num [pixels] to the north
  panNorth([int pixels=100]) => _pan([0,-pixels]);

  /// Pans the viewport num [pixels] to the south.
  panSouth([int pixels=100]) => _pan([0,pixels]);

  /// Pans the viewport num [pixels] to the west
  panWest([int pixels=100]) => _pan([-pixels, 0]);

  /// Pans the viewport num [pixels] to the east
  panEast([int pixels=100]) => _pan([pixels, 0]);

  /* ----------------------- controls pane ------------------------ */
  ControlsPane _controlsPane;

  ControlsPane get controlsPane => _controlsPane;

  set controlsPane(ControlsPane pane) {
    if (pane == _controlsPane) return; // don't add twice
    if (_controlsPane != null) {
      _controlsPane.detach();
      _container.children.remove(_controlsPane.container);
    }
    _controlsPane = pane;
    if (_controlsPane != null) {
      _container.children.add(_controlsPane.container);
      _controlsPane.attach(this);
      _controlsPane.container.style.zIndex = "100";
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

class DoubleClickController {
  final map;
  DoubleClickController(this.map) {
    var stream = new MouseGestureStream.from(map.container).stream;
    stream.where((p) => p.type == MouseGesturePrimitive.DOUBLE_CLICK)
      .listen((p) => _onDoubleClick(p.event));
  }
  _onDoubleClick(evt) => map.zoomIn();
}

class DragController {
  final map;
  Point _dragStart;
  Point _centerOnZoomPlane;

  DragController(this.map) {
    var stream = new MouseGestureStream.from(map.container).stream;
    stream.where((p) => p.isDragPrimitive).listen((p) {
      switch(p.type) {
        case MouseGesturePrimitive.DRAG_START: _onDragStart(p.event); break;
        case MouseGesturePrimitive.DRAG_END: _onDragEnd(p.event); break;
        case MouseGesturePrimitive.DRAG: _onDrag(p.event); break;
      }
    });
  }

  _onDragStart(evt) {
    _dragStart = new Point(evt.offsetX, evt.offsetY);
    _centerOnZoomPlane = map.mapToZoomPlane(map.earthToMap(map.center));
    map.container.style.cursor = "move";
  }

  _onDragEnd(evt) {
    _dragStart = null;
    map.container.style.cursor = "default";
  }

  _onDrag(evt) {
    assert(_dragStart != null);
    var cur = new Point(evt.offsetX, evt.offsetY);
    var c = _centerOnZoomPlane + (_dragStart - cur);
    map.center = map.mapToEarth(map.zoomPlaneToMap(c));
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

  toString() => "{MouseGesturePrimitive: type=${_typeAsString}, x=${event.offsetX},"
     "y=${event.offsetY}";
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
    evt.preventDefault();
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
    evt.preventDefault();
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
    evt.preventDefault();
    _mouseDown = true;
    _lastMouseDownTimestamp = new DateTime.now().millisecondsSinceEpoch;
    _lastMouseDownPos = new Point(evt.offsetX, evt.offsetY);
  }

  _rawMouseUp(MouseEvent evt) {
    evt.preventDefault();
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




