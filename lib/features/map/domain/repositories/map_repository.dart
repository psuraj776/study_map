import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:flutter/material.dart';

class MapRepository {
  Future<List<Polygon>> loadStatePolygons() async {
    try {
      final String geojsonStr = 
          await rootBundle.loadString('assets/layers/india_states.geojson');
      final geojson = GeoJSONFeatureCollection.fromJSON(jsonDecode(geojsonStr));
      
      final polygons = <Polygon>[];
      
      for (final feature in geojson.features) {
        final geom = (feature as GeoJSONFeature?)?.geometry;
        if (geom == null || geom is! GeoJSONPolygon) continue;
        
        if (geom.coordinates.isEmpty) continue;
        final coords = geom.coordinates[0]
            .map((c) => LatLng(c[1], c[0]))
            .toList();
        
        polygons.add(
          Polygon(
            points: coords,
            borderColor: Colors.blue,
            color: Colors.blue.withOpacity(0.3),
            borderStrokeWidth: 2,
          ),
        );
      }
      
      return polygons;
    } catch (e) {
      return [];
    }
  }
/*
  Future<List<Polyline>> loadRiverLines() async {
    try {
      final String geojsonStr = 
          await rootBundle.loadString('assets/layers/india_rivers.geojson');
      final geojson = GeoJSONFeatureCollection.fromJSON(jsonDecode(geojsonStr));
      
      final lines = <Polyline>[];
      
      for (final feature in geojson.features) {
        final geom = (feature as GeoJSONFeature?)?.geometry;
        if (geom == null || geom is! GeoJSONLineString) continue;
        
        if (geom.coordinates.isEmpty) continue;
        final coords = geom.coordinates
            .map((c) => LatLng(c[1], c[0]))
            .toList();
        
        lines.add(
          Polyline(
            points: coords,
            strokeWidth: 2,
            color: Colors.blue,
          ),
        );
      }
      
      return lines;
    } catch (e) {
      return [];
    }
  }
*/
}