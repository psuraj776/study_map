import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:flutter/material.dart';
import '../../../../services/app_logger.dart';
import '../../../../core/constants/geographic_data.dart';

class MapRepository {
  final AppLogger logger;
  
  // Cache for loaded GeoJSON data
  GeoJSONFeatureCollection? _stateGeoData;
  final Map<String, List<Polygon>> _polygonCache = {};

  MapRepository(this.logger);

  /// Load state polygons - simplified approach
  Future<List<Polygon>> loadStatePolygons() async {
    const cacheKey = 'country_states';
    
    // Return from cache if available
    if (_polygonCache.containsKey(cacheKey)) {
      logger.debug('MapRepository', 'Returning cached state polygons');
      return _polygonCache[cacheKey]!;
    }

    final stopwatch = Stopwatch()..start();
    
    try {
      // Try to load from assets, fallback to simplified boundaries
      List<Polygon> polygons;
      
      try {
        final geojsonStr = await rootBundle.loadString('assets/layers/india_states.geojson');
        polygons = _parseGeoJsonToPolygons(geojsonStr, Colors.blue);
        logger.debug('MapRepository', 'Loaded state polygons from GeoJSON');
      } catch (e) {
        // Fallback: Create simplified boundaries from constants
        polygons = _createSimplifiedStatePolygons();
        logger.debug('MapRepository', 'Created simplified state polygons from constants');
      }

      // Cache the result
      _polygonCache[cacheKey] = polygons;
      
      logger.performance('LOAD_STATE_POLYGONS_SUCCESS', stopwatch.elapsedMilliseconds, {
        'polygonCount': polygons.length,
        'usedFallback': polygons.isEmpty,
      });
      
      return polygons;
    } catch (e, stackTrace) {
      logger.error('MapRepository', 'Error loading state polygons: $e', stackTrace);
      return [];
    } finally {
      stopwatch.stop();
    }
  }

  /// Load district polygons for a state
  Future<List<Polygon>> loadDistrictPolygons(String stateId) async {
    final cacheKey = 'state_${stateId}_districts';
    
    // Return from cache if available
    if (_polygonCache.containsKey(cacheKey)) {
      logger.debug('MapRepository', 'Returning cached district polygons for $stateId');
      return _polygonCache[cacheKey]!;
    }

    final stopwatch = Stopwatch()..start();
    
    try {
      final stateInfo = GeographicData.states[stateId];
      if (stateInfo == null || !stateInfo.hasOfflineData) {
        logger.warning('MapRepository', 'No offline data available for state: $stateId');
        return [];
      }

      List<Polygon> polygons;
      
      try {
        final geojsonStr = await rootBundle.loadString('assets/offline_data/${stateId}.geojson');
        polygons = _parseGeoJsonToPolygons(geojsonStr, Colors.orange);
        logger.debug('MapRepository', 'Loaded district polygons from GeoJSON for $stateId');
      } catch (e) {
        logger.warning('MapRepository', 'District GeoJSON not found for $stateId, trying fallback');
        try {
          final geojsonStr = await rootBundle.loadString('assets/layers/${stateId}.geojson');
          polygons = _parseGeoJsonToPolygons(geojsonStr, Colors.orange);
        } catch (e2) {
          logger.warning('MapRepository', 'No district data available for state: $stateId');
          return [];
        }
      }

      // Cache the result
      _polygonCache[cacheKey] = polygons;
      
      logger.performance('LOAD_DISTRICT_POLYGONS', stopwatch.elapsedMilliseconds, {
        'count': polygons.length,
        'stateId': stateId,
      });
      
      return polygons;
    } catch (e, stackTrace) {
      logger.warning('MapRepository', 'Error loading district polygons for $stateId: $e');
      return [];
    } finally {
      stopwatch.stop();
    }
  }

  /// Load taluk polygons for a district
  Future<List<Polygon>> loadTalukPolygons(String districtId) async {
    final cacheKey = 'district_${districtId}_taluks';
    
    // Return from cache if available
    if (_polygonCache.containsKey(cacheKey)) {
      logger.debug('MapRepository', 'Returning cached taluk polygons for $districtId');
      return _polygonCache[cacheKey]!;
    }

    final stopwatch = Stopwatch()..start();
    
    try {
      final districtInfo = GeographicData.districts[districtId];
      if (districtInfo == null || !districtInfo.hasOfflineData) {
        logger.warning('MapRepository', 'No offline data available for district: $districtId');
        return [];
      }

      List<Polygon> polygons;
      
      try {
        final geojsonStr = await rootBundle.loadString('assets/offline_data/${districtId}.geojson');
        polygons = _parseGeoJsonToPolygons(geojsonStr, Colors.green);
        logger.debug('MapRepository', 'Loaded taluk polygons from GeoJSON for $districtId');
      } catch (e) {
        logger.warning('MapRepository', 'Taluk GeoJSON not found for $districtId, trying fallback');
        try {
          final geojsonStr = await rootBundle.loadString('assets/layers/${districtId}.geojson');
          polygons = _parseGeoJsonToPolygons(geojsonStr, Colors.green);
        } catch (e2) {
          logger.warning('MapRepository', 'No taluk data available for district: $districtId');
          return [];
        }
      }

      // Cache the result
      _polygonCache[cacheKey] = polygons;
      
      logger.performance('LOAD_TALUK_POLYGONS', stopwatch.elapsedMilliseconds, {
        'count': polygons.length,
        'districtId': districtId,
      });
      
      return polygons;
    } catch (e, stackTrace) {
      logger.warning('MapRepository', 'Error loading taluk polygons for $districtId: $e');
      return [];
    } finally {
      stopwatch.stop();
    }
  }

  /// Create simplified state boundaries from metadata (fallback)
  List<Polygon> _createSimplifiedStatePolygons() {
    final polygons = <Polygon>[];
    
    for (final state in GeographicData.states.values) {
      final bounds = state.bounds;
      final polygon = Polygon(
        points: [
          LatLng(bounds['minLat']!, bounds['minLng']!),
          LatLng(bounds['maxLat']!, bounds['minLng']!),
          LatLng(bounds['maxLat']!, bounds['maxLng']!),
          LatLng(bounds['minLat']!, bounds['maxLng']!),
          LatLng(bounds['minLat']!, bounds['minLng']!),
        ],
        borderColor: Colors.blue.withOpacity(0.7),
        color: Colors.blue.withOpacity(0.1),
        borderStrokeWidth: 1.0,
      );
      polygons.add(polygon);
    }
    
    logger.debug('MapRepository', 'Created ${polygons.length} simplified state polygons');
    return polygons;
  }

  /// Generic GeoJSON parser
  List<Polygon> _parseGeoJsonToPolygons(String geojsonStr, Color color) {
    try {
      final geojson = GeoJSONFeatureCollection.fromJSON(geojsonStr);
      final polygons = <Polygon>[];

      for (final feature in geojson.features.whereType<GeoJSONFeature>()) {
        final geom = feature.geometry;
        if (geom == null) continue;

        List<List<LatLng>> allPolygonCoords = [];

        if (geom is GeoJSONPolygon && geom.coordinates.isNotEmpty) {
          final coords = _convertCoordinatesToLatLng(geom.coordinates[0]);
          allPolygonCoords.add(coords);
        } else if (geom is GeoJSONMultiPolygon) {
          for (final polygonCoords in geom.coordinates) {
            if (polygonCoords.isNotEmpty) {
              final coords = _convertCoordinatesToLatLng(polygonCoords[0]);
              allPolygonCoords.add(coords);
            }
          }
        }

        for (final coords in allPolygonCoords) {
          polygons.add(
            Polygon(
              points: coords,
              borderColor: color.withOpacity(0.8),
              color: color.withOpacity(0.3),
              borderStrokeWidth: 1.5,
            ),
          );
        }
      }

      return polygons;
    } catch (e) {
      logger.error('MapRepository', 'Error parsing GeoJSON: $e');
      return [];
    }
  }

  List<LatLng> _convertCoordinatesToLatLng(List<dynamic> coordinates) {
    return coordinates
        .cast<List<dynamic>>()
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  }

  /// Find clicked state using bounds checking (fast)
  Future<Map<String, dynamic>?> findClickedState(LatLng clickPoint) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.debug('MapRepository', 'Finding clicked state at: ${clickPoint.latitude}, ${clickPoint.longitude}');
      
      // First try bounds-based detection (fast)
      for (final state in GeographicData.states.values) {
        final bounds = state.bounds;
        if (clickPoint.latitude >= bounds['minLat']! &&
            clickPoint.latitude <= bounds['maxLat']! &&
            clickPoint.longitude >= bounds['minLng']! &&
            clickPoint.longitude <= bounds['maxLng']!) {
          
          final result = {
            'id': state.id,
            'name': state.name,
            'center': state.center,
            'hasOfflineData': state.hasOfflineData,
            'properties': {'bounds': bounds},
          };
          
          logger.mapEvent('STATE_CLICK_DETECTED', {
            'clickPoint': {'lat': clickPoint.latitude, 'lng': clickPoint.longitude},
            'detectedState': state.name,
            'stateId': state.id,
            'detectionTimeMs': stopwatch.elapsedMilliseconds,
            'method': 'bounds_check',
          });
          
          return result;
        }
      }
      
      logger.debug('MapRepository', 'No state found for click point (${stopwatch.elapsedMilliseconds}ms)');
      return null;
    } catch (e, stackTrace) {
      logger.error('MapRepository', 'Error finding clicked state: $e', stackTrace);
      return null;
    } finally {
      stopwatch.stop();
    }
  }

  /// Find clicked district using bounds checking
  Future<Map<String, dynamic>?> findClickedDistrict(LatLng clickPoint, String stateId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.debug('MapRepository', 'Finding clicked district at: ${clickPoint.latitude}, ${clickPoint.longitude} in state: $stateId');
      
      // Get districts for the current state
      final districts = GeographicData.getDistrictsForState(stateId);
      
      for (final district in districts) {
        final bounds = district.bounds;
        if (clickPoint.latitude >= bounds['minLat']! &&
            clickPoint.latitude <= bounds['maxLat']! &&
            clickPoint.longitude >= bounds['minLng']! &&
            clickPoint.longitude <= bounds['maxLng']!) {
          
          final result = {
            'id': district.id,
            'name': district.name,
            'center': district.center,
            'stateId': stateId,
            'hasOfflineData': district.hasOfflineData,
            'properties': {'bounds': bounds},
          };
          
          logger.mapEvent('DISTRICT_CLICK_DETECTED', {
            'clickPoint': {'lat': clickPoint.latitude, 'lng': clickPoint.longitude},
            'detectedDistrict': district.name,
            'districtId': district.id,
            'stateId': stateId,
            'detectionTimeMs': stopwatch.elapsedMilliseconds,
            'method': 'bounds_check',
          });
          
          return result;
        }
      }
      
      logger.debug('MapRepository', 'No district found for click point (${stopwatch.elapsedMilliseconds}ms)');
      return null;
    } catch (e, stackTrace) {
      logger.error('MapRepository', 'Error finding clicked district: $e', stackTrace);
      return null;
    } finally {
      stopwatch.stop();
    }
  }

  /// Get bounds for state (from constants)
  Map<String, double>? getStateBounds(String stateId) {
    final stateInfo = GeographicData.states[stateId];
    return stateInfo?.bounds;
  }

  /// Get bounds for district (from constants)
  Map<String, double>? getDistrictBounds(String districtId) {
    final districtInfo = GeographicData.districts[districtId];
    return districtInfo?.bounds;
  }

  /// Clear cache to free memory
  void clearCache() {
    _polygonCache.clear();
    logger.debug('MapRepository', 'Polygon cache cleared');
  }

  // Placeholder methods for future features
  Future<List<Marker>> loadPOIsForRegion(String regionId, String regionType) async {
    logger.debug('MapRepository', 'POI loading not implemented yet for $regionType: $regionId');
    return [];
  }

  Future<List<Polyline>> loadRiverLines() async {
    logger.debug('MapRepository', 'River loading not implemented yet');
    return [];
  }
}