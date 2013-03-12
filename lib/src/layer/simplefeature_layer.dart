part of dartkart.layer;

/**
 * SimpleFeatureLayer renders a a collection of [Geometry] or [Feature]s
 * as SVG.
 *
 * ## Example
 * [:
 *   m = new MapViewport("#sample-map");
 *   var layer = new SimpleFeatureLayer();
 *   m.addLayer(layer);
 *   // load the world countries
 *   HttpRequest.getString(
 *     "/your/relative/url/countries.geo.json"
 *   ).then((content) {
 *     var countries = parseGeoJson(content);
 *     layer.data  = countries;
 *   });
 * :]
 *
 */
class SimpleFeatureLayer extends Layer {

  @override
  SimpleFeatureLayer([String domId]) : super(domId){
    _scaffold();
  }

  static const _TEMPLATE = """
  <!-- the root svg node - covers the whole map viewport -->
  <svg class="geojson-layer-root viewport" width="100%" height="100%">
    <!-- representing the zoom plane - x,y, width,height are set dynamically -->
    <svg class="zoom-plane">
      <!-- the map plane - the viewBox is set dynamically. SVG elements are
           added here -->
      <svg class="map-plane" width="100%" height="100%">
      </svg>
    </svg>
  </svg>
  """;

  SvgElement _root;
  var _data;

  _scaffold() {
     _root = new SvgElement.svg(_TEMPLATE);
  }

  @override
  attach(MapViewport map) {
    super.attach(map);
    var size = map.viewportSize;
    _container.children.clear();
    _container.children.add(_root);
  }

  /**
   * Sets the data to be rendered.
   *
   * [data] is either
   * * a [Geometry] or a [Feature]
   * * a [GeometryCollection] or a [FeatureCollection]
   *
   * If [data] is null, nothing is rendered.
   */
  set data(data) {
    if (data == null) {
      _data = data;
      _root.query(".map-plane").children.clear();
      return;
    }
    _data = data;
    _root.query(".map-plane").children
      ..clear()
      ..add(_buildSvg(_data));
  }

  @override
  render() {

    // set the coordinate system for the map-plane
    var b = map.crs.projectedBounds;
    var viewBox = "${b.min.x} ${b.min.y} ${b.width} ${b.height}";
    _root.query(".map-plane").attributes["viewBox"] = viewBox;

    var zp = map.zoomPlaneSize;
    _root.query(".zoom-plane")
      ..attributes["width"] = zp.x.toString()
      ..attributes["height"] = zp.y.toString();

    // place the zoom-plane "behind" the map viewport
    var zpCenter = map.mapToZoomPlane(map.earthToMap(map.center));
    var size = map.viewportSize;
    var x = -(zpCenter.x - size.x ~/ 2).toInt();
    var y = -(zpCenter.y - size.y ~/ 2).toInt();
    _root.query(".zoom-plane")
      ..attributes["x"] = x.toString()
      ..attributes["y"] = y.toString();
  }

  //TODO:  the _build_* methods should be factored out in a renderer
  // class which is controlled by rendering rules. The SVG elements
  // should be decorated with appropriate styles and/or classes.

  SvgElement _buildSvg(data) {
    if (data is Point) return _buildSvg_Point(data);
    if (data is MultiPoint) return _buildSvg_MultiPoint(data);
    if (data is LineString) return _buildSvg_LineString(data);
    if (data is Polygon) return _buildSvg_Polygon(data);
    if (data is Feature) return _buildSvg(data.geometry);
    if (data is FeatureCollection) return _buildSvg_FeatureCollection(data);
    if (data is GeometryCollection) return _buildSvg_GeometryCollection(data);
  }

  _buildSvg_FeatureCollection(FeatureCollection fc) {
    var svgs = fc.features.map((f) => _buildSvg(f.geometry)).toList();
    svgs.remove(null);
    var g = new SvgElement.tag("g");
    g.classes.add("sf-feature-collection");
    g.children.addAll(svgs);
    return g;
  }

  _buildSvg_GeometryCollection(GeometryCollection c) {
    var svgs = c.geometries.map((g) => _buildSvg(g)).toList();
    svgs.remove(null);
    var g = new SvgElement.tag("g");
    g.classes.add("sf-geometry-collection");
    g.children.addAll(svgs);
    return g;
  }

  SvgElement _buildSvg_Point(Point g){
    return null;
  }

  SvgElement _buildSvg_MultiPoint(MultiPoint g) {
    return null;
  }

  SvgElement _buildSvg_LineString(LineString g) {

    buildLinearRing() {
      var svg = new SvgElement.tag("path");
      svg.classes.add("sf-linear-ring");
      var sb = new StringBuffer();
      for (int i=0; i< g.length-1; i++) {
        var p = g[i];
        p = map.earthToMap(new LatLon(p.y, p.x));
        sb.write(i == 0 ? " M" : " L");
        sb.write(p.x.toString());
        sb.write(" ");
        sb.write((-p.y).toString());
      }
      sb.write(" Z"); // close the path
      svg.attributes["d"] = sb.toString();
      return svg;
    }

    buildLineString() {
      var svg = new SvgElement.tag("path");
      svg.classes.add(g.isLine ? "sf-line" : "sf-line-string");
      var sb = new StringBuffer();
      for (int i=0; i< g.length; i++) {
        var p = g[i];
        p = map.earthToMap(new LatLon(p.y, p.x));
        sb.write(i == 0 ? "M" : "L");
        sb.write(p.x.toString());
        sb.write(" ");
        sb.write((-p.y).toString());
      }
      svg.attributes["d"] = sb.toString();
      return svg;
    }

    if (g.isLinearRing) {
      return buildLinearRing();
    } else {
      return buildLineString();
    }

  }

  SvgElement _buildSvg_Polygon(Polygon g) {
    var group = new SvgElement.tag("g");
    group.classes.add("sf-polygon");
    var exterior = _buildSvg_LineString(g.exteriorRing);
    exterior.classes.add("sf-exterior-ring");
    group.children.add(exterior);
    for (int i=0; i< g.numInteriorRing; i++) {
      var interior = _buildSvg_LineString(g.interiorRingN(i));
      interior.classes.add("sf-interior-ring");
      group.children.add(interior);
    }
    return group;
  }
}

