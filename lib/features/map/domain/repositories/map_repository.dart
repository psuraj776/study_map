import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geojson_vi/geojson_vi.dart';
import '../../../../core/constants/map_constants.dart';

class MapRepository {
  Future<List<Polygon>> loadStatesLayer() async {
    try {
      final String geojsonStr = await rootBundle.loadString(
        MapConstants.layerPaths['states']!
      );
      final geojson = GeoJSONFeatureCollection.fromJSON(jsonDecode(geojsonStr));
      
      final polygons = <Polygon>[];
      
      for (final feature in geojson.features) {
        final geom = (feature as GeoJSONFeature?)?.geometry;
        if (geom == null || geom is! GeoJSONPolygon) continue;
        
        if (geom.coordinates.isEmpty) continue;
        final coords = geom.coordinates[0].map(
          (c) => LatLng(c[1], c[0])
        ).toList();
        
        polygons.add(
          Polygon(
            points: coords,
            borderColor: MapConstants.layerColors['states']!,
            color: MapConstants.layerColors['states']!.withOpacity(0.3),
            borderStrokeWidth: 2,
          ),
        );
      }
      
      return polygons;
    } catch (e) {
      throw Exception('Failed to load states layer: $e');
    }
  }

  Future<List<Polyline>> loadRiversLayer() async {
    try {
      final String geojsonStr = await rootBundle.loadString(
        MapConstants.layerPaths['rivers']!
      );
      final geojson = GeoJSONFeatureCollection.fromJSON(jsonDecode(geojsonStr));
      
      final polylines = <Polyline>[];
      
      for (final feature in geojson.features) {
        final geom = (feature as GeoJSONFeature?)?.geometry;
        if (geom == null || geom is! GeoJSONLineString) continue;
        
        if (geom.coordinates.isEmpty) continue;
        final coords = geom.coordinates.map(
          (c) => LatLng(c[1], c[0])
        ).toList();
        
        polylines.add(
          Polyline(
            points: coords,
            strokeWidth: 2,
            color: MapConstants.layerColors['rivers']!,
          ),
        );
      }
      
      return polylines;
    } catch (e) {
      throw Exception('Failed to load rivers layer: $e');
    }
  }
}