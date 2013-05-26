part of dartkart.layer;

/**
 * This is the abstract base class for a layer in `dartkart.
 *
 * ## DOM elements
 * * the layer has a `div` as root element, see [container]
 *   with the CSS class `dartkart-layer` and a unique `id`.
 *
 */
abstract class Layer extends Object with PropertyObservable{

  static var _layerIDCounter = 0;
  static get _nextLayerId => _layerIDCounter++;

  MapViewport _map;
  DivElement _container;
  int _nid;

  _defaultDOMId() => "dartkart-layer-$_nid";
  String get _defaultName => "Layer $_nid";

  /**
   * Creates a new layer.
   *
   * If present, [domId] is assigned to the `id` attribute of the layer
   * [container]. Otherwise, a new unique id is created.
   */
  Layer([String domId]) {
    _nid = _nextLayerId;
    if (domId != null) domId = domId.trim();
    if (domId == null || domId.isEmpty) {
      domId = _defaultDOMId();
    }
    _container = new Element.tag("div")
      ..attributes["id"] = domId
      ..classes.add("dartkart-layer");
  }

  /// the unique numeric id for this layer
  int get id => _nid;

  /// the unique layer id
  String get domId => _container.attributes["id"];

  /**
   * Sets the DOM  id on the layer [container].
   *
   * If [value] is null or empty, sets a default id.
   */
  set domId(String value) {
    if (value != null) value = value.trim();
    if (value == null || value.isEmpty) {
      value = _defaultDOMId();
    }
    _container.attributes["id"] = value;
  }

  /// the map this layer is attached to, or null
  MapViewport get map => _map;

  /**
   * Attaches the layer to a map viewport [m].
   *
   * Throws [StateError] if this layer is already attached.
   */
  void attach(MapViewport m) {
    if (_map != null) {
      throw new StateError("layer is already attached");
    }
    _map = m;
  }

  /**
   * Detaches this layer from the map viewport it is
   * currently attached to.
   */
  void detach(){
    _map = null;
  }

  // the [Element] this layer uses as container.
  DivElement get container => _container;

  /**
   * Renders the layer.
   */
  void render();

  /* ------------------------ opacity ------------------------------- */
  double _opacity = 1.0;

  /// the opacity of this layer
  double get opacity => _opacity;

  /// set the opacity of this layer. [value] is a [num] in the range
  /// (0.0 - 1.0). The lower the value, the more transparent the layer.
  set opacity(num value) {
    value = math.max(0, value);
    value = math.min(value, 1);
    var oldvalue = _opacity;
    this._opacity = value.toDouble();
    if (oldvalue != this._opacity) {
      notify("opacity", oldvalue, this._opacity);
      if (_map != null) {
        _map.render();
      }
    }
  }

  /* ------------------------  name------------------------------- */
  String _name;

  /// the layer name
  String get name {
    if (_name == null) return _defaultName;
    return _name;
  }

  /// sets the layer name. If [value] is null or consists of white space only,
  /// a default name is chosen.
  set name(String value) {
    if (value != null) value = value.trim();
    var old = _name;
    if (value == null || value.isEmpty) {
      _name = null;
    } else {
      _name = value;
    }
    notify("name", old, name);
  }

  /* ------------------------  visibility -------------------------- */
  bool _visible = true;

  /// the layer visibility
  bool get visible => _visible;

  /// sets whether this layer is visible or not
  set visible(bool value) {
    var old = _visible;
    if (value != old) {
      if (_container != null) {
        _container.style.visibility =
            value ? "visible" : "hidden";
      }
      _visible = value;
      notify("visible", old, value);
    }
  }
}
