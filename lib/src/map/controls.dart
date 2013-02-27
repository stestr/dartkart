part of dartkart.map;

/**
 * The container class for [MapControl]s. There's exatly one [ControlsPane] in
 * a [MapViewport].
 *
 */
class ControlsPane {
  MapViewport _viewport;
  DivElement _root;

  ControlsPane() {
    _root = new Element.tag("div");
  }

  /// the root DOM element for this control
  DivElement get root => _root;

  /// Detach this pane from the map viewport.
  detach() {
    _viewport = null;
  }

  /// Attach this control pane to the [viewport]. [viewport]
  /// must not be null.
  attach(MapViewport viewport) {
    assert(viewport != null);
    var viewportSize = viewport.viewportSize;
    var tl = viewport.topLeftInPage;
    _root.style
      ..width = "${viewportSize.x}px"
      ..height = "${viewportSize.y}px"
      ..position = "absolute"
      ..top = "${tl.y}px"
      ..left = "${tl.x}px";

    // Don't add the _container to the viewport container,
    // the map viewport takes care of this
  }
}

abstract class MapControl {
  MapViewport _map;
  /// the map this control is attached to, or null
  MapViewport get map => _map;

  /// the list of currently subscriptions
  final List _subscriptions = [];

  /// the container element for the control
  Element _root;

  /// the root DOM element for this map control
  Element get root => _root;

  /**
   * Detaches this control from the map viewport it is currently
   * attached to (if any).
   */
  detach() {
    if (_map == null) return;
    if (_root == null) return;
    if (_map._controlsPane == null) return;
    _map.controlsPane.root.children.remove(_root);
    _subscriptions.forEach((s) => s.cancel());
    _subscriptions.clear();
  }

  attach(MapViewport map) {
    if (map == null) throw new ArgumentError("map must not be null");
    // already attached ?
    if (_map != null) {
      if (_map == map) {
        return;  // don't attach again 
      } else {
        detach(); // detach the currently attached, then attach the new one
      }      
    }
    this._map = map;
    var controlsPane = _map.controlsPane;
    //TODO: log a warning?
    if (controlsPane == null) return;
    _build();
    controlsPane.root.children.add(_root);
  }

  _build();
}

/**
 * An instance of PanControl represents a map control to pan the
 * map viewport ~100 pixels north, east, west, or south.
 *
 * ##Example
 *
 *    var map = new MapViewport("#container");
 *    // this creates the control and adds it to the
 *    // map's controls pane, and registers
 *    var panControl = new PanControl();
 *    panControl.attachTo(map);
 *
 *    // to detach the control from the map
 *    panControl.detachFrom(map);
 *
 */
class PanControl extends MapControl{
  static const SVG_CONTENT = """
  <svg
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   width="100"
   height="100"
   version="1.1">
   <g class="pan-control">
     <circle class="pan-nob" cx="50" cy="50" r="30"/>
     <path class="pan-button pan-north" d="M50 25 l10 10  l-20 0 Z">
       <title>pan north</title>
     </path>
     <path class="pan-button pan-east" d="M75 50 l-10 -10 l0 20 Z">
        <title>pan east</title>
     </path>
     <path class="pan-button pan-south" d="M50 75 l-10 -10 l20 0 Z">
       <title>pan south</title>
     </path>
     <path class="pan-button pan-west" d="M25 50 l10 -10 l0 20 Z">
       <title>pan west</title>
     </path>
   </g> 
  </svg>
  """;

  _wireEventHandlers() {
    register(cls, handler) {
      _subscriptions.add(
          _root.query(".pan-button.$cls").onClick.listen(handler)
      );
    }
    register("pan-north", (e) => _map.panNorth());
    register("pan-east", (e)=>_map.panEast());
    register("pan-south", (e)=>_map.panSouth());
    register("pan-west", (e)=>_map.panWest());

    _root.queryAll(".pan-button").forEach((b) {
      _subscriptions.add(b.onMouseOver.listen((e) => b.classes.add("hover")));
      _subscriptions.add(b.onMouseOut.listen((e) => b.classes.remove("hover")));
    });
  }

  _buildSvg() {
    _root = new Element.tag("div");
    _root.style
      ..position = "absolute"
      ..left = "20px"
      ..top = "20px"
      ..width="100px"
      ..height = "100px";
    var svg = new SvgElement.svg(SVG_CONTENT);
    _root.children.add(svg);
  }

  _build() {
    _buildSvg();
    _wireEventHandlers();
  }

  PanControl();
}

/**
 * A scale indicator control displays information about the current
 * map scale.
 *
 */
//TODO: support other units than 'meters' (ie. degrees) -> configurable
//  similar to Openlayers
class ScaleIndicatorControl extends MapControl {

  static const SVG_CONTENT = """<svg
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns="http://www.w3.org/2000/svg"
  width="200"
  height="100"
  version="1.1">

  <g class="scale-indicator-control">
    <g class="scale-kilometers">
      <rect class="bar" x="0" y="0" width="100" height="15"/>
      <text class="label" x="5" y="12">1000 km</text>

    </g>
    <g class="scale-miles">
      <rect class="bar" x="0" y="20" width="100" height="15"/>
      <text class="label" x="5" y="32">500 mi</text>
    </g>
  </g>
  </svg>
  """;

  ScaleIndicatorControl();

  _build() {
    _root = new Element.tag("div");
    var svg = new SvgElement.svg(SVG_CONTENT);
    var tl = _map.topLeftInPage;
    var size = _map.viewportSize;
    var y = tl.y  + size.y - 100;
    _root.style
      ..position = "absolute"
      ..left = "20px"
      ..top = "${y}px"
      ..width="200px"
      ..height = "100px";
    _root.children.add(svg);

    _subscriptions.add(_map.onZoomChanged.listen((e) => _refresh()));
    _refresh();
  }

  _100PixelDistance() {
    var zh = _map.zoomPlaneSize.x;
    var w = _map.crs.projectedBounds.width;
    var dist = 100 / zh * w;
    return dist;
  }

  String _formatMeterDistance(m) {
    if (m > 1000) {
      m = m ~/ 1000;
      m = m.round().toInt();
      return "$m km";
    } else if (m > 0) {
      m = m.round().toInt();
      return "$m m";
    } else if (m < 0) {
      m = (m * 100).round().toInt();
      return "$m cm";
    }
  }

  String _formatMilesDistance(ft) {
    if (ft > 5000) {
      ft = (ft * 0.000189394).round().toInt();
      return "$ft mi";
    } else if (ft > 0) {
      ft = ft.round().toInt();
      return "$ft ft";
    } else {
      ft = (ft * 10).round().toInt();
      return "$ft in";
    }
  }

  _refresh() {
    var m = _100PixelDistance();
    var ft = m * 3.28084;
    _root.query(".scale-kilometers text").text = _formatMeterDistance(m);
    _root.query(".scale-miles text").text = _formatMilesDistance(ft);
  }
}

/**
 * A control element for controling the zoom level.
 */
class ZoomControl extends MapControl{

  static const SVG_CONTENT = """<svg
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns="http://www.w3.org/2000/svg"
  version="1.1">
  <!-- for styles see CSS file in the assets directory -->
  <g class="zoom-control">
    <!-- content is created dynamically -->
  </g>
  </svg>
  """;

  ZoomControl();

  _zoomIn(evt) => _map.zoomIn();
  _zoomOut(evt) => _map.zoomOut();

  _onZoomLevelClick(evt) {
    try {
       var zoom = int.parse(evt.target.dataset["zoom"]);
       print("setting zoom: $zoom");
      _map.zoom = zoom;
    } catch(e) {
      print(e);
    }
  }

  _onZoomChanged(evt) {
    var levels = _root.queryAll(".zoom-level");
    levels.forEach((l) => l.classes.remove("current"));
    levels.firstMatching((el) => el.dataset["zoom"] == "${evt.newValue}")
          .classes.add("current");
  }

  _build() {
    _buildSvg();
    _wireEventHandlers();
  }

  _buildSvg() {
    _root = new Element.tag("div");
    var svg = new SvgElement.svg(SVG_CONTENT);
    svg.attributes["width"] = "40";
    svg.attributes["height"] = "250";

    var control = svg.query(".zoom-control");

    var zoomInNob = new SvgElement.svg("""
      <g class="zoom-in-nob">
      <rect x="0" y="0" width="20" height="20">
        <title>Zoom in</title>
      </rect>
      <line x1="10" y1="3" x2="10" y2="17" />
      <line x1="3" y1="10" x2="17" y2="10" />
      </g>
      """
    );

    var zoomOutNob = new SvgElement.svg("""
        <g transform="translate(0, 200)" class="zoom-out-nob">
          <rect x="0" y="0" width="20" height="20">
           <title>Zoom out</title>
          </rect>
          <line x1="3" y1="10" x2="17" y2="10"/>
        </g>
        """
    );

    var levels = [];
    for (int i = 0; i<=20; i++) {
      var level = new SvgElement.svg("""
        <rect x="0" y="${25 + (i * 8)}" width="20" height="6" data-zoom="${20-i}">
        <title>Set zoom level ${20-i}</title>
        </rect>
      """);
      level.classes.add("zoom-level");
      if (_map.zoom == (20 -i)) level.classes.add("current");
      levels.add(level);
    }

    control.children.add(zoomInNob);
    control.children.add(zoomOutNob);
    levels.forEach((l) => control.children.add(l));
    _root.children.add(svg);

    var tl = _map.topLeftInPage;
    var y = tl.y  + 100;

    _root.style
        ..position = "absolute"
        ..left = "20px"
        ..top = "${y}px"
        ..width="200px"
        ..height = "100px";
  }

  _wireEventHandlers() {
    _root.queryAll(".zoom-level").forEach((el) {
      _subscriptions.add(el.onMouseOver.listen((evt) {
        evt.target.classes.add("hover");
      }));
      _subscriptions.add(el.onMouseOut.listen((evt) {
        evt.target.classes.remove("hover");
      }));
      _subscriptions.add(el.onClick.listen(_onZoomLevelClick));
    });

    _onMouseOver(evt) {
      var parent = evt.target.parent;
      parent.classes.add("hover");
    }
    _onMouseOut(evt) {
      var parent = evt.target.parent;
      parent.classes.remove("hover");
    }

    [_root.query(".zoom-in-nob"), _root.query(".zoom-out-nob")]
    .forEach((el) {
      _subscriptions.add(el.onMouseOver.listen(_onMouseOver));
      _subscriptions.add(el.onMouseOut.listen(_onMouseOut));
    });
    _subscriptions.add(_root.query(".zoom-in-nob").onClick.listen(_zoomIn));
    _subscriptions.add(_root.query(".zoom-out-nob").onClick.listen(_zoomOut));

    _subscriptions.add(_map.onZoomChanged.listen(_onZoomChanged));
  }
}

//TODO: listen to layer change events
//TODO: listen to layer name changes 
class LayerControl extends MapControl {
  static const _TEMPLATE = """
  <div class="layer-control">
  <table>
  </table>
  </div>
  """;
  
  static const _ROW_TEMPLATE = """
  <tr>
   <td class="layer-visibility"><input type="checkbox"></td>
   <td class="layer-name"><span title=""></span></td>   
  </tr>
  """;
  
  Element _buildLayerRow(Layer layer) {
    var tr = new Element.html(_ROW_TEMPLATE);
    var span = tr.query("td.layer-name").query("span");
    span.innerHtml = layer.name;
    span.attributes["title"] = layer.name; // tooltip
    var cb = tr.query("input");
    if (layer.visible) {
      cb.attributes["checked"] = "checked";
    } else {
      cb.attributes.remove("checked");
    }
    cb.dataset["layerId"] = layer.id.toString();
    return tr;
  }
  
  _buildHtml() {
    _root = new Element.html(_TEMPLATE);
    var size = _map.viewportSize;
    var left = size.x - 20 - 200;
    _root.style
      ..left = "${left}px"
      ..top = "20px";
      
    var rows = _map.layers.map((l) => _buildLayerRow(l));
    var table = _root.query("table");
    table.children.clear();
    table.children.addAll(rows);
  }
  
  _wireEventListeners() {
    _subscriptions.addAll(
       _root.queryAll("input").map((cb) => cb.onClick.listen(_toggleLayerVisibility))
    );
  }
  
  _toggleLayerVisibility(evt) {
    var cb = evt.target;
    var lid = cb.dataset["layerId"];
    if (lid == null) return; //TODO: warning
    try {
      lid = int.parse(lid);
    } catch(e) {
      //TODO: warning 
      return;
    }
    var layer = _map.layers.firstMatching((l) => l.id == lid);
    if (layer == null) {
      //TODO: warning
      return;
    }
    var visible = !layer.visible;
    layer.visible = visible;    
  }
  
  _build() {    
    _buildHtml();
    _wireEventListeners();
  }
}

