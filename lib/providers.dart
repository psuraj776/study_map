import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:latlong2/latlong.dart';

// 1. STATE for Layer Visibility

// This class will hold the state of which layers are visible.
class LayerVisibility extends StateNotifier<Map<String, bool>> {
  LayerVisibility() : super({
    'states': true, // States are visible by default
    'rivers': false, // Rivers are hidden by default
  });

  void toggle(String layer) {
    state = {
      ...state,
      layer: !state[layer]!,
    };
  }
}

// The provider that the UI will use to interact with the LayerVisibility state.
final layerVisibilityProvider = StateNotifierProvider<LayerVisibility, Map<String, bool>>(
  (ref) => LayerVisibility(),
);

// 2. PROVIDERS for Loading Data

// A FutureProvider to asynchronously load and parse the states GeoJSON.
final statesProvider = FutureProvider<List<Polygon>>((ref) async {
  final geojsonStr = await rootBundle.loadString('assets/india_states.geojson');
  final geojson = GeoJSONFeatureCollection.fromJSON(jsonDecode(geojsonStr));
  
  final polygons = <Polygon>[];
  for (final feature in geojson.features) {
    final geom = (feature as GeoJSONFeature?)?.geometry;
    if (geom is GeoJSONPolygon) {
      final coords = geom.coordinates[0].map((c) => LatLng(c[1], c[0])).toList();
      polygons.add(
        Polygon(
          points: coords,
          borderColor: Colors.blue,
          color: Colors.blue.withOpacity(0.3),
          borderStrokeWidth: 2,
        ),
      );
    }
  }
  return polygons;
});

// A FutureProvider to asynchronously load and parse the rivers GeoJSON.
final riversProvider = FutureProvider<List<Polyline>>((ref) async {
  final geojsonStr = await rootBundle.loadString('assets/india_rivers.geojson');
  final geojson = GeoJSONFeatureCollection.fromJSON(jsonDecode(geojsonStr));

  final polylines = <Polyline>[];
  for (final feature in geojson.features) {
    final geom = (feature as GeoJSONFeature?)?.geometry;
    if (geom is GeoJSONLineString) {
      final coords = geom.coordinates.map((c) => LatLng(c[1], c[0])).toList();
      polylines.add(
        Polyline(points: coords, strokeWidth: 3, color: Colors.green.shade300),
      );
    }
  }
  return polylines;
});