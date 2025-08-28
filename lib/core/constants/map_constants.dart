import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class MapConstants {
  static const LatLng indiaCenter = LatLng(20.5937, 78.9629);
  static const double defaultZoom = 4.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;
  
  static const Map<String, String> layerPaths = {
    'states': 'assets/layers/india_states.geojson',
    'rivers': 'assets/layers/india_rivers.geojson',
  };

  static const Map<String, Color> layerColors = {
    'states': Colors.blue,
    'rivers': Colors.blue,
  };

  static const String mbtilePath = 'assets/basemaps/india_basemap.mbtiles';
}