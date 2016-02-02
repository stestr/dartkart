part of dartkart.layer;

/**
 * An abstract strategy class for rendering a grid of image tiles
 * covering the map viewport.
 */
abstract class Renderer {

  TileLayer _layer;

  /// Creates a renderer for a tile [_layer]
  Renderer(this._layer);

  /// Invoked by a [TileLayer] to render itself
  void render() {
    beforeRender();
    renderTileGrid();
    afterRender();
  }

  /**
   * Invoked before the tile grid is rendered using [renderTileGrid].
   * Default implementation is empty. Override in subclasses if
   * necessary.
   */
  void beforeRender(){}

  /**
   * Renders the tile grid
   */
  void renderTileGrid() {
    var map = _layer._map;
    var tileSize = _layer.tileSize;
    var centerOnZoomPlane = map.mapToZoomPlane(map.earthToMap(map.center));
    var vshalf = (map.viewportSize / 2).toInt();
    var topLeftOnZoomPlane = new Point2D(
        centerOnZoomPlane.x - vshalf.width,
        centerOnZoomPlane.y - vshalf.height
    );
    var viewportOnZoomPlaneBounds = new Bounds(
        topLeftOnZoomPlane,
        topLeftOnZoomPlane + map.viewportSize
    );
    tileIntersectsWithViewport(Point2D t) {
      var tl = t.scale(sx:tileSize.width, sy:tileSize.height);
      var tileBounds = new Bounds(
          tl,
          tl + tileSize
      );
      return viewportOnZoomPlaneBounds.intersects(tileBounds);
    }

    // the tile covering the map center
    var tile = new Point2D(
        centerOnZoomPlane.x ~/ tileSize.width,
        centerOnZoomPlane.y ~/ tileSize.height
    );

    // find the first tile to be rendered
    while(true) {
      var candidate = tile.translate(dx:-1);
      if (candidate.x < 0) break;
      if (! tileIntersectsWithViewport(candidate)) break;
      tile = candidate;
    }
    while(true) {
      var candidate = tile.translate(dy:-1);
      if (candidate.y < 0) break;
      if (! tileIntersectsWithViewport(candidate)) break;
      tile = candidate;
    }

    // render the tile grid intersecting with the viewport
    var maxTileX = (1 << map.zoom);
    var maxTileY = (1 << map.zoom);
    var cur = new Point2D.from(tile);
    while(cur.x < maxTileX && tileIntersectsWithViewport(cur)) {
      while(cur.y < maxTileY && tileIntersectsWithViewport(cur)) {
        renderTile(cur);
        cur = cur.translate(dy:1);
      }
      cur = new Point2D(cur.x + 1, tile.y);
    }
  }

  /**
   * Invoked after the tile grid is rendered using [renderTileGrid].
   * Default implementation is empty. Override in subclasses if
   * necessary.
   */
  void afterRender(){}

  /**
   * Renders the tile at position [tileCoord] in the current
   * tile plane.
   */
  void renderTile(Point2D tileCoord);
}

/**
 * Tile represents a map tile. 
 */
class Tile {
  /// indicates that the tile is loading the tile image
  static const LOADING = 0;
  /// indicates that the tile image is ready for rendering
  static const READY = 1;
  /// indicates that an error occured when loading the tile image
  static const ERROR= 2;

  /// the tile coordinats
  final Point2D tc;
  /// the layer this tile is rendered on 
  final TileLayer layer;
  
  CanvasElement _canvas;
  ImageElement _img;
  int _state = LOADING;

  /**
   * Creates a tile at tile coordinates [tc] = (ti, tj)
   * for the layer [layer]. It will be rendered on
   * [_canvas].
   */
  Tile(this.tc, this._canvas, this.layer);

  /**
   * Detach the tile from the map viewport.
   *
   * A detached tile whose image becomes available isn't
   * rendered anymore.
   */
  void detach() => _canvas = null;

  /**
   * Trigger loading of the tile image.
   */
  void load() {
     var url = layer.bindTileToUrl(tc.x, tc.y, layer.map.zoom);
     _img = _DEFAULT_CACHE.lookup(url,
      onLoad: (e) {
        _state = READY;
        render();
      },
      onError: (e) {
        _state = ERROR;
        render();
      }
    );
     _state = _img.complete ? READY : LOADING;
    render();
  }

  /// the top left corner in viewport coordinates where the tile
  /// should be rendered
  Point2D get _topLeftInViewport =>
      layer.map.zoomPlaneToViewport(tc.scale(
          sx: layer.tileSize.width,
          sy: layer.tileSize.height
      ));

  void _renderReady() {
    if (_canvas == null) return;
    var context = _canvas.context2D;
    context.globalAlpha = layer.opacity;
    var tl = _topLeftInViewport;
    var ts = layer.tileSize;
    context.clearRect(tl.x, tl.y, ts.width, ts.height);
    context.drawImage(_img, tl.x, tl.y);
  }

  /// Returns the image of the parent tile of this tile, provided 
  /// there is a parent tile and its image is already in the cache.
  /// Otherwise returns [:null:].
  ImageElement get _parentImage {
    var z = layer.map.zoom;
    if (z == 0) return null;
    z--;
    var ti = tc.x ~/ 2;
    var tj = tc.y ~/ 2;
    var url = layer.bindTileToUrl(ti, tj, z);
    var img = _DEFAULT_CACHE.get(url);
    return img;
  }

  void _renderLoading() {
    var img = _parentImage;
    var context = _canvas.context2D;
    if (img == null) {      
      var tl = _topLeftInViewport;
      var ts = layer.tileSize;
      context.clearRect(tl.x,tl.y, ts.width, ts.height);
    } else {
      var tl = _topLeftInViewport;
      var ts = layer.tileSize;
      // the quadrant of the parent tile to be rendered (scaled by 2)
      // in place of the current tile
      var src = new math.Rectangle(
          (tc.x % 2) * ts.width ~/ 2,
          (tc.y % 2) * ts.height ~/ 2,
          ts.width ~/ 2,
          ts.height ~/ 2
      );
      // the rectangle where the current tile is rendered
      var dest = new math.Rectangle(tl.x, tl.y, ts.width, ts.height);
      context.drawImageToRect(img,dest,sourceRect:src);
    }
  }

  void _renderError() {
    var context = _canvas.context2D;
    context.globalAlpha = layer.opacity;
    var ts = layer.tileSize;
    var tl = _topLeftInViewport;
    var center = 
         new Point2D(tl.x, tl.y) 
      + (new Point2D(ts.width, ts.height) / 2).toInt();
    
    context
      ..save()
      ..strokeStyle="rgba(255,0,0,0.5)"
      ..lineWidth=10
      ..beginPath()
      ..arc(center.x, center.y, 50, 0, math.PI * 2, true)
      ..stroke()
      ..beginPath()
      ..moveTo(center.x - 30, center.y -30)
      ..lineTo(center.x + 30, center.y + 30)
      ..moveTo(center.x - 30, center.y + 30)
      ..lineTo(center.x +30 , center.y - 30)
      ..stroke()
      ..restore()
      ;
  }

  /// renders the tile
  void render() {
    if (_canvas == null) return;
    switch(_state) {
      case LOADING: _renderLoading(); break;
      case READY: _renderReady(); break;
      case ERROR: _renderError(); break;
    }
  }
}

/**
 * A renderer which renders map tiles with a grid of [ImgElements]s.
 */
class ImgGridRenderer extends Renderer {
  ImgGridRenderer(layer) : super(layer);

  void beforeRender(){
    _layer.container.children.clear();
  }

  void renderTile(Point2D tile) {
    var url = _layer.bindTileToUrl(tile.x, tile.y, _layer.map.zoom);
    var img = _layer._cache.lookup(url);
    var tileOnZoomPlane = tile.scale(
        sx: _layer.tileSize.width,
        sy: _layer.tileSize.height
    );
    var tileOnViewport = _layer._map.zoomPlaneToViewport(tileOnZoomPlane);
    img.style
      ..position = "absolute"
      ..left = "${tileOnViewport.x.toString()}px"
      ..top = "${tileOnViewport.y.toString()}px"
      ..opacity = "${_layer.opacity}";
    _layer._container.children.add(img);
  }
}

/**
 * A renderer which renders map tiles on a [Canvas] element.
 */
class CanvasRenderer extends Renderer {

  CanvasElement _canvas;
  CanvasRenderingContext2D get _context {
    if (_canvas == null) return null;
    return _canvas.context2D;
  }
  
  List<Tile> _tiles = [];

  CanvasRenderer(TileLayer layer): super(layer);

  _clear() {
    if (_context == null) return;
    _context
      ..save()
      ..setTransform(1, 0, 0, 1, 0, 0)
      ..clearRect(0, 0, _canvas.width, _canvas.height)
      ..restore();
    _tiles.forEach((t) => t.detach());
    _tiles.clear();
  }

  @override 
  void beforeRender() {
    if (_layer.map == null) {
      _canvas = null;
    } else {
      if (_canvas == null) {
        _canvas = new Element.tag("canvas");
        _layer.container.children.add(_canvas);
        _canvas.style
          ..width="100%"
          ..height="100%"
          ..top="0px"
          ..left="0px"
          ..position="relative"
          ..zIndex = "inherit";
      }
      _updateSize();
      _clear();
    }
  }

  _updateSize() {
    var vs = _layer.map.viewportSize;
    // make sure the _canvas size is equal to the map
    // size
    if (vs.width != _canvas.width || vs.height != _canvas.height) {
      _canvas
        ..width=vs.width
        ..height=vs.height;
    }
  }

  @override
  void renderTile(Point2D tileCoord) {
    Tile t = new Tile(tileCoord, _canvas, _layer);
    _tiles.add(t);
    t.load();
  }

  /* ------------- rendering the tile border - for debugging  --- */
  bool renderTileBorders = false;
}

/**
 * Renderer constant for [ImgGridRenderer]. Use it when creating a tile
 * layer.
 *
 * ### Example
 *        var layer = new OsmTileLayer(renderer: IMG_GRID_RENDERER);
 */
const IMG_GRID_RENDERER = 0;

/**
 * Renderer constant for [CanvasRenderer]. Use it when creating a tile
 * layer.
 *
 * ### Example
 *       var layer = new OsmTileLayer(renderer: CANVAS_RENDERER);
 */
const CANVAS_RENDERER = 1;

/**
 * The abstract base class for map layers consisting of a grid of
 * map tiles.
 */
abstract class TileLayer extends Layer {

  /// the default tile dimensions
  static final Dimension DEFAULT_TILE_SIZE = new Dimension(256,256);

  final TileCache _cache = new TileCache();
  Renderer _renderer;

  /**
   * initializes the layer renderer from [renderer]
   *
   * [renderer] is either a [Renderer] or one of the constants
   * [IMG_GRID_RENDERER] or [CANVAS_RENDERER]
   */
  _initRenderer(renderer) {
    initPredefined(code) {
      switch(code) {
        case IMG_GRID_RENDERER: _renderer = new ImgGridRenderer(this); break;
        case CANVAS_RENDERER: _renderer = new CanvasRenderer(this); break;
        default:
           throw new ArgumentError("unsupported renderer code, got $code");
      }
    };
    initCustom(renderer) {
      if (renderer == null) {
        _renderer = new CanvasRenderer(this);
      } else {
        _renderer = renderer;
      }
    };

    if (renderer is int) initPredefined(renderer);
    else if (renderer is Renderer) initCustom(renderer);
    else if(renderer == null) _renderer = new CanvasRenderer(this);
    else
      throw new ArgumentError(
          "renderer: expected int or Renderer, got $renderer");
  }

  /**
   * Creates the tile renderer.
   *
   * ### Possible values for [renderer]
   * 
   * * [IMG_GRID_RENDERER] or [CANVAS_RENDERER]
   * * an instance of a [Renderer]
   * * the default value if missing or null is [CANVAS_RENDERER]
   */
  TileLayer({renderer:CANVAS_RENDERER}) {
    _initRenderer(renderer);
    _container = new Element.tag("div");
    _container
      ..classes.add("dartkart-layer")
      ..style.overflow = "hidden";
  }

  /// the tile size used by this tile layer
  Dimension get tileSize => DEFAULT_TILE_SIZE;

  @override
  void attach(MapViewport m) {
    super.attach(m);
    var viewportSize = map.viewportSize;
    var tl = map.topLeftInPage;
    _container.style
      ..width="100%"
      ..height="100%"
      ..position = "absolute"
      ..left = "0px"
      ..top = "0px";
  }

  /// returns a tile URL for the tile at tile coordinates [x], [y]
  /// in the tile plane at zoom level [zoom]
  String bindTileToUrl(int x, int y, int zoom);

  @override
  void render() {
    if (!visible) return;
    _renderer.render();
  }
}

/**
 * A tile layer which renders map tiles provided by the 
 * OpenStreetMap project.
 */
class OsmTileLayer extends TileLayer {

  OsmTileLayer({tileSources, renderer:CANVAS_RENDERER})
      : super(renderer:renderer)
  {
     this.tileSources = tileSources;
  }

  List _tileSources;

  /// the list of tile sources this layer uses
  List get tileSources => new List.from(_tileSources);

  /**
   * Set the tile sources where tiles are loaded from.
   * 
   * If more than one tile source is supplied, the layer loads map
   * tile in random order from them.
   *
   * ## Possible values for [sources] 
   * 
   * * [:null:] which results in an empty list of tile sources
   * * a [String] with a tile URL template
   * * a [List] of strings, a tile URL template each
   *
   * A *tile URL template* is a string which can include the following
   * macros:
   * 
   *   * `{z}` -  bound to the current zoom level when a tile is loaded
   *   * `{x}` -  bound to the x-coordiate of the tile when a tile is loaded
   *   * `{y}` -  bound to the y-coordiate of the tile when a tile is loaded
   */
  void set tileSources(sources) {
    if (sources == null) {
      _tileSources = null;
    } else  if (sources is String) {
      _tileSources = new List.filled(1, sources);
    } else if (sources is List) {
      sources = sources.where((s) => s != null);
      _require(sources.every((s) => s is String),
        "Expected list tile source strings, got $sources");     
      _tileSources = new List.from(sources, growable: false);
    }
  }

  var _random = new math.Random();

  /// selects a random tile source from the list of configured tile sources
  String get _randomTileSource {
    if (_tileSources == null) return null;
    if (_tileSources.length == 1) return _tileSources.first;
    return _tileSources[_random.nextInt(_tileSources.length)];
  }

  static final _TEMPLATE_BIND_REGEXP = new RegExp(r"\{\s*(x|y|z)\s*\}");
  
  @override
  String bindTileToUrl(int x, int y, int zoom) {
    var source = _randomTileSource;
    return source.splitMapJoin(
      _TEMPLATE_BIND_REGEXP,
      onMatch: (Match m) {
        switch(m.group(1).toLowerCase()) {
          case "x": return x.toString();
          case "y": return y.toString();
          case "z": return zoom.toString();
        }
    });
  }
}

/**
 * `WMSLayer` loads map tiles from a Web Map Server.
 */
class WMSLayer extends TileLayer {

  String _serviceUrl;
  final List<String> _layers = [];
  Map<String, String> _defaultParameters;

  _initParameters(Map userParameters) {
    if (userParameters == null) {
      userParameters = {};
    }

    _defaultParameters = new Map();
    // normalize case
    userParameters.keys.forEach((k) {
      _defaultParameters[k.toUpperCase()] = userParameters[k];
    });
    if (!_defaultParameters.containsKey("SERVICE")) {
      _defaultParameters["SERVICE"] = "WMS";
    }
    if (!_defaultParameters.containsKey("VERSION")) {
      _defaultParameters["VERSION"] = "1.0.0";
    }
    if (!_defaultParameters.containsKey("FORMAT")) {
      _defaultParameters["FORMAT"] = "image/png";
    }
    if (!_defaultParameters.containsKey("SRS")) {
      _defaultParameters["SRS"] = "EPSG:4326";
    }
  }
  /**
   * [serviceUrl] is base URL of the WMS server.
   *
   * [layers] is either a single layer name or a list of layer
   * names.
   *
   * [parameters] is a map of WMS request parameters.
   * 
   * [renderer] is one of the renderer values supported by
   * [TileLayer].
   *
   * ##Examples
   *      var layer1 = new WmsLayer(
   *        serviceUrl: "https://wms.geo.admin.ch?",
   *        layers: "ch.are.gemeindetypen"
   *      );
   *
   *      var layer2 = new WmsLayer(
   *        serviceUrl: "https://wms.geo.admin.ch?",
   *        layers: ["ch.are.gemeindetypen", "ch.are.alpenkonvention"],
   *        parameters: {
   *          "FORMAT": "image/jpeg"
   *        }
   *      );
   */
  WMSLayer({String serviceUrl, layers, Map parameters, renderer})
    : super(renderer:renderer)
  {
      if (serviceUrl != null) this.serviceUrl = serviceUrl;
      if (layers != null) this.layers = layers;
      _initParameters(parameters);
  }

  /// the layer(s) to be loaded from the WMS server
  List<String> get layers => _layers;

  /**
   * Sets the layer(s) to be retrieved from the WMS server.
   *
   * ## Possible values
   * * [String] - a single layer
   * * [List] - a list of layer names
   */
  void set layers(value) {
    if (value is String) {
      _layers.clear();
      _layers.add(value);
    } else if (value is List) {
      _layers.clear();
      _layers.addAll(value);
    } else {
      throw new ArgumentError("expected String or list thereof, got $value");
    }
  }

  /// sets the service URL
  void set serviceUrl(String value) {
    if (value != null && value.endsWith("?")) {
      value = value.substring(0, value.length -1);
    }
    _serviceUrl = value;
  }

  /// the URL of the WMS server or null, if the server URL
  /// isn't configured yet
  String get serviceUrl => _serviceUrl;

  /**
   * Builds the tile bounding box for tile ([x],[y]) in geographic
   * coordinates.
   */
  //TODO: Order of components in the bbox string changed in WMS 1.3.0?
  String _buildGeographicTileBBox(int x, int y, int zoom) {
    var size = tileSize;
    var tx = x * tileSize.width;
    var ty = y * tileSize.height + (tileSize.height - 1);
    var min = map.mapToEarth(map.zoomPlaneToMap(new Point2D(tx, ty)));

    tx = tx + tileSize.width - 1;
    ty = y * tileSize.height;
    var max = map.mapToEarth(map.zoomPlaneToMap(new Point2D(tx, ty)));
    return "${min.lon},${min.lat},${max.lon},${max.lat}";
  }

  /**
   * Indicates whether the bounding box of a WMS `GetMap`request is
   * expressed in geographic or in projected coordinates.
   *
   * * if false, the bounding box is expressed in geographic coordinates,
   *   i.e. in WGS84 aka
   *   [EPSG:4326](http://spatialreference.org/ref/epsg/4326/)
   *
   * * if true, the bounding box is expressed in projected coordinates,
   *   that is coordinate reference system configured on the
   *   map viewport, see [MapViewport.crs].
   *
   * Default value is false.
   */
  bool useProjectedCoordinates = false;

  /**
   * Builds the tile bounding box for tile ([x],[y]) in projected
   * coordinates
   */
  //TODO: Order of components in the bbox string changed in WMS 1.3.0?
  String _buildProjectedTileBBox(int x, int y, int zoom) {
    var tx = x * tileSize.width;
    var ty = y * tileSize.height + (tileSize.height - 1);
    var min = map.zoomPlaneToMap(new Point2D(tx, ty));

    tx = tx + tileSize.width - 1;
    ty = y * tileSize.height;
    var max = map.zoomPlaneToMap(new Point2D(tx, ty));
    return "${min.x},${min.y},${max.x},${max.y}";
  }

  @override
  String bindTileToUrl(int x, int y, int zoom) {
    var ts = tileSize;
    var parameters = new Map.from(_defaultParameters);
    parameters["REQUEST"] = "GetMap";
    parameters["LAYERS"] = _layers.join(",");
    parameters["WIDTH"] = ts.width.toString();
    parameters["HEIGHT"] = ts.height.toString();
    if (useProjectedCoordinates) {
      parameters["BBOX"] = _buildProjectedTileBBox(x,y,zoom);
      parameters["SRS"] = _map.crs.code;
    } else {
      parameters["BBOX"] = _buildGeographicTileBBox(x,y,zoom);
      parameters["SRS"] = "EPSG:4326";
    }

    var query = parameters.keys.map((k) => "$k=${parameters[k]}").join("&");
    var url = "$_serviceUrl?$query";
    return url;
  }

  @override
  void render() {
    if (_serviceUrl == null) {
      print("WARNING: can't render, serviceUrl not defined");
      return;
    }
    if (_layers.isEmpty) {
      print("WARNING: can't render, no layers defined");
      return;
    }
    super.render();
  }
}

/**
 * An instance of this class maintains a cache of [ImageElement]s for
 * already downloaded map tiles.
 *
 * The size of the cache is bound. The least recently accessed map tile
 * is removed from the cache first, if the upper limit of the maps size
 * is reached.
 */
class TileCache {

  /// default tile cache size
  static const DEFAULT_CAPACITY = 200;

  final Map<String, ImageElement>  _map = new Map();
  final Queue<ImageElement> _access = new Queue();

  final int capacity;

  /**
   * Creates the tile cache with [capacity] as upper
   * capacity limit.
   */
  TileCache({this.capacity: DEFAULT_CAPACITY});

  /**
   *  Lookup (or create) an [ImageElement] for [url].
   *
   *  If the image isn't in the cache then [onLoad] and [onError]
   *  are invoked later when the image is successfully loaded or
   *  when an error occurs respectively.
   */
  ImageElement lookup(String url, {onLoad(event), onError(event)}) {
    var img = _map[url];
    if (img != null) {
      _access.remove(img);
      _access.addFirst(img);
      return img;
    }
    img = new Element.tag("img");
    _map[url] = img;
    if (_access.length >= capacity) {
      _access.removeLast();
    }
    _access.addFirst(img);
    var sub1, sub2;
    cancel() => [sub1, sub2].where((s) => s!=null).forEach((s) => s.cancel());
    if (onLoad != null) {
      sub1 = img.onLoad.listen((e) {
        cancel();
        onLoad(e);
      });
    }
    if (onError != null) {
      sub2 = img.onError.listen((e) {
        cancel();
        onError(e);
      });
    }

    //TODO: temporary- replace later
    img.onAbort.listen((e) {
      print("Image loading -> aborted ...");
    });
    img.src = url;
    return img;
  }

  /**
   * Replies the tile image for [url] if it is already in the cache
   * and complete. Otherwise, returns null.
   */
  ImageElement get(String url) {
    var img = _map[url];
    if (img != null && img.complete) {
      _access.remove(img);
      _access.addFirst(img);
      return img;
    } else {
      return null;
    }
  }

  /**
   * Purges [obj] from the cache.
   *
   * ## Possible values for [obj]
   * 
   * * an URL as [String]
   * * an [ImageElement]
   *
   * Otherwise throws an [ArgumentError].
   *
   * Nothing is purged from the cache if [obj] is null.
   */
  void purge(obj) {
    if (obj == null) return;
    if (obj is String) {
      obj = _map[obj];
    } else if (obj is ImageElement) {
      obj = _map.values.firstWhere((img) => img == obj);
    } else {
      throw new ArgumentError("expected a String or an ImageElement, "
          "got $obj"
      );
    }
    if (obj == null) return;
    _access.remove(obj);
    _map.remove(obj.src);
  }
}

/// the default internal tile cache
final _DEFAULT_CACHE = new TileCache();
