part of dartkart.map;

/**
 * MouseEvent is an event triggered by mouse gestures. In contrast
 * to the fundamental [html.MouseEvent] class it can represent 
 * the mouse events in a drag operation. Instead of a bare bone
 * 'mouse move' event it can represent a 'mouse hover' or 
 * a 'mouse drag' event.
 */
class MouseEvent {
  static const int CLICK = 0;
  static const int DOUBLE_CLICK = 1;
  static const int DRAG_START = 2;
  static const int DRAG = 3;
  static const int DRAG_END = 4;
  static const int HOVER = 5;

  /// the type of the mouse event 
  final int type;
  
  /// the underlying DOM mouse event 
  final html.MouseEvent event;
  
  /**
   * Create a mouse event of type [type] connected to the 
   * underlying DOM mouse [event].
   */
  MouseEvent(this.type, this.event);
  
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

  /// returns true if this mouse event is a drag event
  bool get isDragEvent => type == DRAG_START || type == DRAG ||
      type == DRAG_END;

  @override
  toString() => "{MouseEvent: type=${_typeAsString}, x=${event.offset.x},"
     " y=${event.offset.y}";
}

/**
 * `MouseEventStream` transforms the bare bone DOM events into a stream
 * of higher level [MouseEvents]. 
 * 
 * A `MouseEventStream` originates at an DOM [Element] 
 * which the stream is attached to.
 * 
 */
class MouseEventStream {
  var _controler = new StreamController();
  var _subscriptions = [];

  var _lastMouseDownPos = null;
  var _lastMouseDownTimestamp = 0;
  var _mouseDown = false;
  var _isDragging = false;

  /// Creates a new stream which isn't attached to any element
  MouseEventStream();
  
  /// Creates a new stream which is attached to [source]. 
  MouseEventStream.from(Element source) {
    attach(source);
  }

  var _deferredEvent = null;

  _fireDeferred() {
    if (_deferredEvent != null) {
      var e = _deferredEvent;
      _deferredEvent = null;
      _controler.sink.add(new MouseEvent(MouseEvent.CLICK, e));
    }
  }

  _rawMouseClick(evt) {
    if (_deferredEvent == null) {
      var ts = new DateTime.now().millisecondsSinceEpoch;
      if (ts - _lastMouseDownTimestamp > 150) {
        // a click generated at the end of a drag sequence
        //      mouse down, mouse move, ..., mouse move, mouse up, click
        // Ignore it.
        return;
      }
      _deferredEvent = evt;
      new Timer(const Duration(milliseconds: 200), () => _fireDeferred());
    } else {
      _deferredEvent = null;
      _controler.sink.add(new MouseEvent(MouseEvent.DOUBLE_CLICK,evt));
    }
  }

  _rawMouseMove(evt){
    if (_mouseDown) {
       if (!_isDragging) {
         _controler.sink.add(new MouseEvent(MouseEvent.DRAG_START, evt));
       }
      _isDragging = true;
    }
    if (_isDragging) {
      _controler.sink.add(new MouseEvent(MouseEvent.DRAG, evt));
    } else {
      _controler.sink.add(new MouseEvent(MouseEvent.HOVER, evt));
    }
  }

  _rawMouseDown(html.MouseEvent evt) {
    if (evt.button != 0 /* left */) return;
    evt.preventDefault();
    evt.stopPropagation();
    _mouseDown = true;
    _lastMouseDownTimestamp = new DateTime.now().millisecondsSinceEpoch;
    _lastMouseDownPos = new Point2D(evt.offset.x, evt.offset.y);
  }

  _rawMouseUp(html.MouseEvent evt) {
    if (evt.button != 0 /* left */) return;
    evt.preventDefault();
    evt.stopPropagation();
    if (_isDragging) {
      _controler.sink.add(new MouseEvent(MouseEvent.DRAG_END, evt));
    }
    _mouseDown = false;
    _isDragging = false;
  }

  get stream => _controler.stream;

  /// Detach from source and cancel all event subsriptions
  void detach() {
    _subscriptions
      ..forEach((s) => s.cancel())
      ..clear();
  }

  /// Attach to [source] and process its raw mouse events.
  void attach(Element source) {
    _subscriptions.add(source.onClick.listen(_rawMouseClick));
    _subscriptions.add(source.onMouseDown.listen(_rawMouseDown));
    _subscriptions.add(source.onMouseUp.listen(_rawMouseUp));
    _subscriptions.add(source.onMouseMove.listen(_rawMouseMove));
  }
}