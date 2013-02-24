# dartkart

_dartkart_ is  framwork for web cartografy in the tradition of the
JavaScript libraries [OpenLayers](http://www.openlayers.org) and 
[Leaflet](http://leafletjs.com/). It is neither a 1:1 port of 
them nor does it provide the full functionality of either of them, 
but it has a similar structure and borrows a lot of ideas from them.


## Example
1.  Create a HTML page `sample_map.html` embedding a map
	<pre><code>
	&lt;!DOCTYPE html&gt;
	&lt;html&gt;
	  &lt;head&gt;
	    &lt;style type="text/css"&gt;
	      #sample-map {height: 400px; width: 400px;}
	 	 &lt;/style&gt;
	  &lt;/head&gt;
	  &lt;body&gt;
	    &lt;div id="sample-map"&gt;&lt;/div&gt;	
	    &lt;script type="application/dart" src="sample_map.dart"&gt;&lt;/script&gt;
	    &lt;script src="packages/browser/dart.js"&gt;&lt;/script&gt;
	  &lt;/body&gt;
	&lt;/html&gt;
	</pre></code>
	
2. Create the dart application file `sample_map.dart` 

	```dart		
	import "package:dartkart/dartkart.dart";
	import "dart:async";
	import "dart:html";
	
	main() {
	  var map = new MapViewport("#sample-map");
	  map
	    ..zoom = 8
	    ..center = new LatLon(46.8, 8);
	  
	  // a tile layer from the Open Street Map project
	  var source = "http://a.tile.openstreetmap.org/{z}/{x}/{y}.png";
	  var osmLayer = new OsmTileLayer(tileSources:source);

      // a WMS layer provided by the Swiss government 
	  var serviceUrl = "https://wms.geo.admin.ch?";
	  var wmsLayer = new WMSLayer(
	      serviceUrl: serviceUrl,
	      layers: "ch.are.gemeindetypen"
	  );
	  wmsLayer.opacity = 0.4;
	
	  map.addLayer(osmLayer);
	  map.addLayer(wmsLayer);
	}
	```

## Status
This is work in progress. APIs and documentation are unstable. 

## Author
Karl Guggisberg <karl.guggisberg@guggis.ch>

## License 

* (c) Karl Guggisberg, 2013
* Released under GPL 3.0, see LICENSE file 