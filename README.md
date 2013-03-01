# dartkart

_dartkart_ is a framework for web cartografy in the tradition of the
JavaScript libraries [OpenLayers](http://www.openlayers.org) and 
[Leaflet](http://leafletjs.com/). It is neither a 1:1 port of 
them nor does it provide the full functionality of either of them, 
but it has a similar structure and borrows a lot of ideas from them.

## Example
See the demo in the examples directory.

## Status
This is work in progress. APIs and documentation are unstable. 

Currently supported:

  - a basic map viewport (the coordinate reference system EPSG:4326
    is currently fixed) supporting a stack of layers
  - a basic tile layer for OpenStreetMap map tiles
  - a basic tile layer for WMS sources (provided they accept the SRS
	EPSG:4326)	
  - a couple of map controls for panning and zooming the map, for
    displaying the map scale and for a list of layers. 

More to come later (hopefully ...)

## Author
Karl Guggisberg <karl.guggisberg@guggis.ch>

## License 

* (c) Karl Guggisberg, 2013
* Released under GPL 3.0, see LICENSE file 