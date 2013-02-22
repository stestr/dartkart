part of dartkart.map;

class ControlsPane {
  MapViewport _viewport;
  DivElement _container;

  ControlsPane() {
    _container = new Element.tag("div");
  }

  DivElement get container => _container;

  detach() {
    _viewport = null;
  }

  attach(MapViewport viewport) {
    assert(viewport != null);
    var viewportSize = viewport.viewportSize;
    var tl = viewport.topLeftInPage;
    _container.style
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
  Element _container;
  
  /// the container element for the control 
  Element get container => _container;
  
  /**
   * Detaches this control from the map viewport it is currently
   * attached to (if any).
   */
  detach() {
    if (_map == null) return;
    if (_container == null) return; 
    if (_map._controlsPane == null) return;
    _map.controlsPane.container.children.remove(_container);    
    _subscriptions.forEach((s) => s.cancel());
    _subscriptions.clear();
  }
  
  attach(MapViewport map) {
    if (map == null) throw new ArgumentError("map must not be null");
    // already attached ?
    if (_map != null && _map == map) return;
    if (_map != null && _map != map) {
      detach();
    }
    this._map = map;
    var controlsPane = _map.controlsPane;
    //TODO: log a warning?
    if (controlsPane == null) return;
    _build();
    controlsPane.container.children.add(_container);
  }
  
  _build();
}

/**
 * An instance of PanControl represents a map control to pan the
 * map viewport ~100 pixels north, east, west, or south.
 *
 * Example:
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
          _container.query(".pan-button.$cls").onClick.listen(handler)
      );
    }
    register("pan-north", (e) => _map.panNorth());
    register("pan-east", (e)=>_map.panEast());
    register("pan-south", (e)=>_map.panSouth());
    register("pan-west", (e)=>_map.panWest());

    _container.queryAll(".pan-button").forEach((b) {
      _subscriptions.add(b.onMouseOver.listen((e) => b.classes.add("hover")));
      _subscriptions.add(b.onMouseOut.listen((e) => b.classes.remove("hover")));
    });
  }

  _buildSvg() {
    _container = new Element.tag("div");
    _container.style
      ..position = "absolute"
      ..left = "20"
      ..top = "20"
      ..width="100px"
      ..height = "100px";
    var svg = new SvgElement.svg(SVG_CONTENT);
    _container.children.add(svg);
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
    _container = new Element.tag("div");
    var svg = new SvgElement.svg(SVG_CONTENT);
    var tl = _map.topLeftInPage;
    var size = _map.viewportSize;
    var y = tl.y  + size.y - 100;
    _container.style
      ..position = "absolute"
      ..left = "20px"
      ..top = "${y}px"
      ..width="200px"
      ..height = "100px";
    _container.children.add(svg);
    
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
    _container.query(".scale-kilometers text").text = _formatMeterDistance(m);
    _container.query(".scale-miles text").text = _formatMilesDistance(ft);
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
    var levels = _container.queryAll(".zoom-level");
    levels.forEach((l) => l.classes.remove("current"));
    levels.firstMatching((el) => el.dataset["zoom"] == "${evt.newValue}")
          .classes.add("current");
  }
  
  _build() {
    _buildSvg();
    _wireEventHandlers();
  }       

  _buildSvg() {
    _container = new Element.tag("div");
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
    _container.children.add(svg);
    
    var tl = _map.topLeftInPage;
    var y = tl.y  + 100;
    
    _container.style
        ..position = "absolute"
        ..left = "20px"
        ..top = "${y}px"
        ..width="200px"
        ..height = "100px";
  }
  
  _wireEventHandlers() {
    _container.queryAll(".zoom-level").forEach((el) {
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
    
    [_container.query(".zoom-in-nob"), _container.query(".zoom-out-nob")]
    .forEach((el) {
      _subscriptions.add(el.onMouseOver.listen(_onMouseOver));
      _subscriptions.add(el.onMouseOut.listen(_onMouseOut));
    });
    _subscriptions.add(_container.query(".zoom-in-nob").onClick.listen(_zoomIn));
    _subscriptions.add(_container.query(".zoom-out-nob").onClick.listen(_zoomOut));
    
    _subscriptions.add(_map.onZoomChanged.listen(_onZoomChanged));
  }
}


