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
  render() {
    beforeRender();
    renderTileGrid();
    afterRender();
  }

  beforeRender(){}

  renderTileGrid() {
    var map = _layer._map;
    var tileSize = _layer.tileSize;
    var centerOnZoomPlane = map.mapToZoomPlane(map.earthToMap(map.center));
    var topLeftOnZoomPlane = centerOnZoomPlane - (map.viewportSize / 2).round();
    var viewportOnZoomPlaneBounds = new Bounds(
        topLeftOnZoomPlane,
        topLeftOnZoomPlane + map.viewportSize
    );
    tileIntersectsWithViewport(Point t) {
      var tl = t * tileSize;
      var tileBounds = new Bounds(
          tl,
          tl + tileSize
      );
      return viewportOnZoomPlaneBounds.intersects(tileBounds);
    }

    // the tile covering the map center
    var tile = new Point(
        centerOnZoomPlane.x ~/ tileSize.x,
        centerOnZoomPlane.y ~/ tileSize.y
    );

    // find the first tile to be rendered
    while(true) {
      var candidate = tile.translate(-1, 0);
      if (candidate.x < 0) break;
      if (! tileIntersectsWithViewport(candidate)) break;
      tile = candidate;
    }
    while(true) {
      var candidate = tile.translate(0, -1);
      if (candidate.y < 0) break;
      if (! tileIntersectsWithViewport(candidate)) break;
      tile = candidate;
    }

    // render the tile grid intersecting with the viewport
    var maxTileX = (1 << map.zoom);
    var maxTileY = (1 << map.zoom);
    var cur = new Point.from(tile);
    while(cur.x < maxTileX && tileIntersectsWithViewport(cur)) {
      while(cur.y < maxTileY && tileIntersectsWithViewport(cur)) {
        renderTile(cur);
        cur = cur.translate(0,1);
      }
      cur = new Point(cur.x + 1, tile.y);
    }
  }

  afterRender(){}

  renderTile(Point tilePos);
}

typedef String TileUrlBuilder(int x, int y, int zoom);

class Tile {
  static const LOADING = 0;
  static const READY = 1;
  static const ERROR= 2;

  final Point t;
  CanvasElement canvas;
  final TileLayer layer;
  ImageElement _img;
  int _state = LOADING;

  Tile(this.t, this.canvas, this.layer);

  detach() => canvas = null;

  load() {
     var url = layer.bindTileToUrl(t.x, t.y, layer.map.zoom);
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

  Point get imageTopLeft =>
      layer.map.zoomPlaneToViewport(t * layer.tileSize);

  renderReady() {
    if (canvas == null) return;
    var context = canvas.context2d;
    context.globalAlpha = layer.opacity;
    var tl = imageTopLeft;
    var ts = layer.tileSize;
    //context.clearRect(tl.x, tl.y, ts.x, ts.y);
    context.drawImage(_img, tl.x, tl.y);
  }

  ImageElement parentImage() {
    var z = layer.map.zoom;
    if (z == 0) return null;
    z--;
    var ti = t.x ~/ 2;
    var tj = t.y ~/ 2;
    var url = layer.bindTileToUrl(ti, tj, z);
    var img = _DEFAULT_CACHE.get(url);
    return img;
  }

  renderLoading() {
    var img = parentImage();
    if (img == null) {
      var context = canvas.context2d;
      var tl = imageTopLeft;
      var ts = layer.tileSize;
      context.clearRect(tl.x,tl.y, ts.x /* width */, ts.y /* height */);
    } else {
      var tl = imageTopLeft;
      var ts = layer.tileSize;
      canvas.context2d.drawImage(img,
          (t.x % 2) * ts.x ~/ 2,
          (t.y % 2) * ts.y ~/ 2,
          ts.x ~/ 2,
          ts.y ~/ 2,
          tl.x, tl.y, ts.x, ts.y
      );
    }
  }

  renderError() {
    var context = canvas.context2d;
    context.globalAlpha = layer.opacity;
    var ts = layer.tileSize;
    var tl = imageTopLeft;
    var center = new Point(tl.x, tl.y) + (new Point(ts.x, ts.y) / 2).toInt();
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

  render() {
    if (canvas == null) return;
    switch(_state) {
      case LOADING: renderLoading(); break;
      case READY: renderReady(); break;
      case ERROR: renderError(); break;
    }
  }
}

/**
 * A renders which renders map tiles with a grid of [ImgElements]s.
 */
class ImgGridRenderer extends Renderer {
  ImgGridRenderer(layer) : super(layer);

  beforeRender(){
    _layer.container.children.clear();
  }

  renderTile(Point tile) {
    var url = _layer.bindTileToUrl(tile.x, tile.y, _layer.map.zoom);
    var img = _layer._cache.lookup(url);
    var tileOnZoomPlane = tile * _layer.tileSize;
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
  CanvasRenderingContext2D _context;
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

  beforeRender() {
    if (_layer.map == null) {
      _canvas = null;
      _context = null;
      return;
    }
    if (_layer.map != null && _canvas != null) {
      _clear();
    } else {
      _canvas = new Element.tag("canvas");
      _layer.container.children.add(_canvas);
      var viewportSize = _layer.map.viewportSize;
      var tl = _layer.map.topLeftInPage;
      _canvas
        ..width=viewportSize.x
        ..height=viewportSize.y;

      _canvas.style
          ..width="${viewportSize.x}px"
          ..height="${viewportSize.y}px"
          ..top="0px"
          ..left="0px"
          ..position="relative"
          ..zIndex = "inherit";
      _context = _canvas.context2d;
      _clear();
    }
  }

  renderTile(Point tile) {
    Tile t = new Tile(tile, _canvas, _layer);
    _tiles.add(t);
    t.load();
  }

  /* ---------------------- rendering the tile border - for debugging  --- */
  bool renderTileBorders = false;
}

/**
 * Renderer constant for [ImgGridRenderer]. Use it when creating a tile
 * layer.
 *
 * ### Example
 *    var layer = new OsmTileLayer(renderer: IMG_GRID_RENDERER);
 */
const IMG_GRID_RENDERER = 0;

/**
 * Renderer constant for [CanvasRenderer]. Use it when creating a tile
 * layer.
 *
 * ### Example
 *    var layer = new OsmTileLayer(renderer: CanvasRenderer);
 */
const CANVAS_RENDERER = 1;

/**
 * The abstract base class for map layers consisting of a grid of
 * map tiles.
 */
abstract class TileLayer extends Layer {

  /// the default tile dimensions
  static final Point DEFAULT_TILE_SIZE = new Point(256,256);

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
      throw new ArgumentError("renderer: expected int or Renderer, got $renderer");
  }

  /**
   * Creates the tile renderer.
   *
   * ### Possible values for [renderer]
   * * either [IMG_GRID_RENDERER] or [CANVAS_RENDERER]
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

  /**
   * The tile size used by this tile layer. Replies a
   * [Point], `x` is the tile width, `y` the tile
   * heigth.
   */
  Point get tileSize => DEFAULT_TILE_SIZE;

  attach(MapViewport m) {
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

  bindTileToUrl(int x, int y, int zoom);

  render() {
    if (!visible) return;
    _renderer.render();
  }
}

class OsmTileLayer extends TileLayer {


  OsmTileLayer({tileSources, renderer:CANVAS_RENDERER})
      : super(renderer:renderer)
  {
    if (?tileSources) this.tileSources = tileSources;
  }

  List _tileSources = [];

  /// the list of tile sources this layer uses
  List get tileSources => new List.from(_tileSources);

  /**
   * Set the tile sources where tiles are loaded from.
   *
   * [sources] can be
   *   * [:null:] which results in an empty list of tile sources
   *   * a [String] with a tile URL template
   *   * a [List] of strings, a tile URL template each
   *
   * A *tile URL template* is a string which can include the following
   * macros:
   *   * `{z}` -  bound to the current zoom level when a tile is loaded
   *   * `{x}` -  bound to the x-coordiate of the tile when a tile is loaded
   *   * `{y}` -  bound to the y-coordiate of the tile when a tile is loaded
   */
  set tileSources(sources) {
    if (sources == null) {
      _tileSources = [];
    } else  if (sources is String) {
      _tileSources = [sources];
    } else if (sources is List) {
      sources = sources.where((s) => s != null);
      if (sources.any((s) => s is! String)) {
        throw new ArgumentError("Expected list tile source strings, got sources");
      }
      _tileSources = new List.from(sources);
    }
  }

  var _random = new math.Random();

  /// selects a random tile source from the list of configured tile sources
  String get _randomTileSource {
    if (_tileSources.isEmpty) return null;
    if (_tileSources.length == 1) return _tileSources.first;
    return _tileSources[_random.nextInt(_tileSources.length)];
  }

  static final _TEMPLATE_BIND_REGEXP = new RegExp(r"\{\s*(x|y|z)\s*\}");
  bindTileToUrl(int x, int y, int zoom) {
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
   * ##Examples
   *    var layer1 = new WmsLayer(
   *      serviceUrl: "https://wms.geo.admin.ch?",
   *      layers: "ch.are.gemeindetypen"
   *    );
   *
   *    var layer2 = new WmsLayer(
   *      serviceUrl: "https://wms.geo.admin.ch?",
   *      layers: ["ch.are.gemeindetypen", "ch.are.alpenkonvention"],
   *      parameters: {
   *        "FORMAT": "image/jpeg"
   *      }
   *    );
   */
  WMSLayer({String serviceUrl, layers, Map parameters, renderer})
    : super(renderer:renderer)
  {
      if (?serviceUrl) this.serviceUrl = serviceUrl;
      if (?layers) this.layers = layers;
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
  set layers(value) {
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
  set serviceUrl(String value) {
    if (value.endsWith("?")) {
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
  String buildGeographicTileBBox(int x, int y, int zoom) {
    var size = tileSize;
    var tx = x * tileSize.x;
    var ty = y * tileSize.y + (tileSize.y - 1);
    var min = map.mapToEarth(map.zoomPlaneToMap(new Point(tx, ty)));

    tx = tx + tileSize.x - 1;
    ty = y * tileSize.y;
    var max = map.mapToEarth(map.zoomPlaneToMap(new Point(tx, ty)));
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
  String buildProjectedTileBBox(int x, int y, int zoom) {
    var size = tileSize;
    var tx = x * tileSize.x;
    var ty = y * tileSize.y + (tileSize.y - 1);
    var min = map.zoomPlaneToMap(new Point(tx, ty));

    tx = tx + tileSize.x - 1;
    ty = y * tileSize.y;
    var max = map.zoomPlaneToMap(new Point(tx, ty));
    return "${min.x},${min.y},${max.x},${max.y}";
  }

  bindTileToUrl(int x, int y, int zoom) {
    var ts = tileSize;
    var parameters = new Map.from(_defaultParameters);
    parameters["REQUEST"] = "GetMap";
    parameters["LAYERS"] = _layers.join(",");
    parameters["WIDTH"] = ts.x.toString();
    parameters["HEIGHT"] = ts.y.toString();
    if (useProjectedCoordinates) {
      parameters["BBOX"] = buildProjectedTileBBox(x,y,zoom);
      parameters["SRS"] = _map.crs.code;
    } else {
      parameters["BBOX"] = buildGeographicTileBBox(x,y,zoom);
      parameters["SRS"] = "EPSG:4326";
    }

    var query = parameters.keys.map((k) => "$k=${parameters[k]}").join("&");
    var url = "$_serviceUrl?$query";
    return url;
  }

  render() {
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
 *
 */
class TileCache {

  /// default tile cache size
  static const DEFAULT_SIZE = 200;

  final Map<String, ImageElement>  _map = new Map();
  final Queue<ImageElement> _access = new Queue();

  final int size;

  /**
   * Creates the tile cache with [size] as upper
   * capacity limit.
   */
  TileCache({this.size: DEFAULT_SIZE});

  /**
   *  Lookup (or create) an [ImageElement] for the [url].
   *
   *  If the image isn't in the cache then [onLoad] and [onError]
   *  are invoked later when the image is successfully loaded or
   *  when an error occurs respectively.
   */
  ImageElement lookup(String url, {onLoad(event), onError(event)}){
    var img = _map[url];
    if (img != null) {
      _access.remove(img);
      _access.addFirst(img);
      return img;
    }
    img = new Element.tag("img");
    _map[url] = img;
    if (_access.length >= size) {
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
   * * an URL as [String]
   * * an [ImageElement]
   *
   * Otherwise throws an [ArgumentError].
   *
   * Nothing is purged from the cache if [obj] is null.
   */
  purge(obj) {
    if (obj == null) return;
    if (obj is String) {
      obj = _map[obj];
    } else if (obj is ImageElement) {
      obj = _map.values.firstMatching((img) => img == obj);
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
