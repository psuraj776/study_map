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

  // Method for loading district polygons (placeholder for future implementation)
  Future<List<Polygon>> loadDistrictPolygons(String stateId) async {
    try {
      // TODO: Implement when district data is available
      // For now, return empty list since you don't have district data
      final String geojsonStr = 
          await rootBundle.loadString('assets/layers/districts/${stateId}_districts.geojson');
      
      final geojson = GeoJSONFeatureCollection.fromJSON(jsonDecode(geojsonStr));
      
      final polygons = <Polygon>[];
      
      for (final feature in geojson.features) {
        final geom = (feature as GeoJSONFeature?)?.geometry;
        //feature.geometry;
        if (geom == null || geom is! GeoJSONPolygon) continue;
        
        if (geom.coordinates.isEmpty) continue;
        final coords = geom.coordinates[0]
            .map((c) => LatLng(c[1], c[0]))
            .toList();
        
        polygons.add(
          Polygon(
            points: coords,
            borderColor: Colors.green,
            color: Colors.green.withOpacity(0.3),
            borderStrokeWidth: 2,
          ),
        );
      }
      
      return polygons;
    } catch (e) {
      // Return empty list when district data is not available
      print('District data not available for state: $stateId');
      return [];
    }
  }

  // Method for loading taluk polygons (placeholder for future implementation)
  Future<List<Polygon>> loadTalukPolygons(String districtId) async {
    try {
      // TODO: Implement when taluk data is available
      final String geojsonStr = 
          await rootBundle.loadString('assets/layers/taluks/${districtId}_taluks.geojson');
      
      // Similar implementation as above
      return [];
    } catch (e) {
      print('Taluk data not available for district: $districtId');
      return [];
    }
  }

  // Method for loading POI markers (placeholder for future implementation)
  Future<List<Marker>> loadPOIsForRegion(String regionId, String regionType) async {
    try {
      // TODO: Implement when POI data is available
      final String geojsonStr = 
          await rootBundle.loadString('assets/layers/pois/${regionType}_${regionId}_pois.geojson');
      
      // Parse POI data and return markers
      return [];
    } catch (e) {
      print('POI data not available for $regionType: $regionId');
      return [];
    }
  }
/*
  // Method for rivers (currently commented out)
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