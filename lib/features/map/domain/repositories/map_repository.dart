import 'dart:convert';
import 'dart:math' as math; // Add this line
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:flutter/material.dart';
import '../../../../services/app_logger.dart';

class MapRepository {
  final AppLogger logger;
  
  // Cache for loaded GeoJSON data
  GeoJSONFeatureCollection? _stateGeoData;
  GeoJSONFeatureCollection? _currentDistrictGeoData;
  String? _currentStateId;

  MapRepository(this.logger);

  Future<List<Polygon>> loadStatePolygons() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.debug('MapRepository', 'Loading state polygons from assets');
      
      // Add better error handling for asset loading
      String geojsonStr;
      try {
        geojsonStr = await rootBundle.loadString('assets/layers/india_states.geojson');
        logger.debug('MapRepository', 'Successfully loaded GeoJSON string, length: ${geojsonStr.length}');
      } catch (e) {
        logger.error('MapRepository', 'Failed to load GeoJSON asset file', e);
        throw Exception('GeoJSON file not found: assets/layers/india_states.geojson');
      }
      
      // Validate JSON format first
      Map<String, dynamic> jsonData;
      try {
        final dynamic parsed = jsonDecode(geojsonStr);
        if (parsed is Map<String, dynamic>) {
          jsonData = parsed;
        } else {
          throw Exception('GeoJSON root is not a Map');
        }
        logger.debug('MapRepository', 'Successfully parsed JSON data');
      } catch (e) {
        logger.error('MapRepository', 'Failed to parse GeoJSON', e);
        throw Exception('Invalid GeoJSON format in india_states.geojson: $e');
      }
      
      // Create GeoJSONFeatureCollection from the original string
      GeoJSONFeatureCollection geojson;
      try {
        geojson = GeoJSONFeatureCollection.fromJSON(geojsonStr);
        logger.debug('MapRepository', 'Successfully created GeoJSONFeatureCollection with ${geojson.features.length} features');
      } catch (e) {
        logger.error('MapRepository', 'Failed to create GeoJSONFeatureCollection', e);
        throw Exception('Failed to parse GeoJSON FeatureCollection: $e');
      }
      
      // Cache the GeoJSON data for click detection
      _stateGeoData = geojson;
      
      final polygons = <Polygon>[];
      int processedFeatures = 0;
      
      // Use whereType to filter out null features
      for (final feature in geojson.features.whereType<GeoJSONFeature>()) {
        try {
          final geom = feature.geometry;
          if (geom == null) {
            logger.debug('MapRepository', 'Skipping feature with null geometry');
            continue;
          }
          
          // Handle both Polygon and MultiPolygon geometries
          List<List<LatLng>> allPolygonCoords = [];
          
          if (geom is GeoJSONPolygon) {
            logger.debug('MapRepository', 'Processing Polygon geometry');
            if (geom.coordinates.isNotEmpty) {
              final coords = _convertCoordinatesToLatLng(geom.coordinates[0]);
              if (coords.length >= 3) {
                allPolygonCoords.add(coords);
              }
            }
          } else if (geom is GeoJSONMultiPolygon) {
            logger.debug('MapRepository', 'Processing MultiPolygon geometry with ${geom.coordinates.length} polygons');
            // MultiPolygon: coordinates is List<List<List<List<double>>>>
            for (final polygonCoords in geom.coordinates) {
              if (polygonCoords.isNotEmpty) {
                // Take the first (outer) ring of each polygon
                final coords = _convertCoordinatesToLatLng(polygonCoords[0]);
                if (coords.length >= 3) {
                  allPolygonCoords.add(coords);
                }
              }
            }
          } else {
            logger.debug('MapRepository', 'Skipping feature with unsupported geometry: ${geom.runtimeType}');
            continue;
          }
          
          // Create Flutter polygons from all coordinate sets
          for (final coords in allPolygonCoords) {
            polygons.add(
              Polygon(
                points: coords,
                borderColor: Colors.black.withValues(alpha: 0.5),
                color: Colors.blue.withValues(alpha: 0.2),
                borderStrokeWidth: 2,
              ),
            );
          }
          
          if (allPolygonCoords.isNotEmpty) {
            processedFeatures++;
            logger.debug('MapRepository', 'Successfully processed feature $processedFeatures with ${allPolygonCoords.length} polygon(s)');
          }
          
        } catch (e) {
          logger.warning('MapRepository', 'Failed to create polygon from feature: $e');
          continue;
        }
      }
      
      logger.performance('LOAD_STATE_POLYGONS_SUCCESS', stopwatch.elapsedMilliseconds, {
        'polygonCount': polygons.length,
        'featureCount': geojson.features.length,
        'processedFeatures': processedFeatures,
      });
      
      logger.info('MapRepository', 'Successfully loaded ${polygons.length} state polygons from ${processedFeatures} features');
      return polygons;
    } catch (e, stackTrace) {
      logger.error('MapRepository', 'Error loading state polygons', e, stackTrace);
      return [];
    } finally {
      stopwatch.stop();
    }
  }

  // Helper method to convert coordinates to LatLng
  List<LatLng> _convertCoordinatesToLatLng(List<dynamic> coordinates) {
    return coordinates
        .cast<List<dynamic>>()
        .map((c) {
          if (c.length >= 2) {
            final lng = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lng);
          } else {
            throw Exception('Invalid coordinate format: $c');
          }
        })
        .toList();
  }

  // Method to find which state was clicked
  Future<Map<String, dynamic>?> findClickedState(LatLng clickPoint) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.debug('MapRepository', 'Finding clicked state at: ${clickPoint.latitude}, ${clickPoint.longitude}');
      
      // If we don't have state data loaded, load it
      if (_stateGeoData == null) {
        logger.debug('MapRepository', 'State data not cached, loading...');
        await loadStatePolygons();
      }
      
      if (_stateGeoData == null) {
        logger.warning('MapRepository', 'No state data available for click detection');
        return null;
      }
      
      logger.debug('MapRepository', 'Checking ${_stateGeoData!.features.length} features for click detection');
      
      // Use whereType to filter out null features
      for (final feature in _stateGeoData!.features.whereType<GeoJSONFeature>()) {
        try {
          final geom = feature.geometry;
          if (geom == null) continue;
          
          // Handle both Polygon and MultiPolygon for click detection
          List<List<LatLng>> allPolygonCoords = [];
          
          if (geom is GeoJSONPolygon) {
            if (geom.coordinates.isNotEmpty) {
              final coords = _convertCoordinatesToLatLng(geom.coordinates[0]);
              allPolygonCoords.add(coords);
            }
          } else if (geom is GeoJSONMultiPolygon) {
            for (final polygonCoords in geom.coordinates) {
              if (polygonCoords.isNotEmpty) {
                final coords = _convertCoordinatesToLatLng(polygonCoords[0]);
                allPolygonCoords.add(coords);
              }
            }
          }
          
          // Check if point is inside any of the polygons
          for (final coords in allPolygonCoords) {
            if (_isPointInPolygon(clickPoint, coords)) {
              final properties = feature.properties ?? {};
              
              final result = {
                'id': properties['id'] ?? properties['ST_NM'] ?? properties['name'] ?? 'unknown',
                'name': properties['name'] ?? properties['ST_NM'] ?? 'Unknown State',
                'center': _getPolygonCenter(coords),
                'properties': properties,
              };
              
              logger.mapEvent('STATE_CLICK_DETECTED', {
                'clickPoint': {'lat': clickPoint.latitude, 'lng': clickPoint.longitude},
                'detectedState': result['name'],
                'stateId': result['id'],
                'detectionTimeMs': stopwatch.elapsedMilliseconds,
              });
              
              return result;
            }
          }
        } catch (e) {
          logger.warning('MapRepository', 'Error processing feature for click detection: $e');
          continue;
        }
      }
      
      logger.debug('MapRepository', 'No state found for click point (${stopwatch.elapsedMilliseconds}ms)');
      return null;
    } catch (e, stackTrace) {
      logger.error('MapRepository', 'Error finding clicked state', e, stackTrace);
      return null;
    } finally {
      stopwatch.stop();
    }
  }

  // NEW: Method to find which district was clicked within a state
  Future<Map<String, dynamic>?> findClickedDistrict(LatLng clickPoint, String stateId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.debug('MapRepository', 'Finding clicked district at: ${clickPoint.latitude}, ${clickPoint.longitude} in state: $stateId');
      
      // Load district data if not cached or if state changed
      if (_currentDistrictGeoData == null || _currentStateId != stateId) {
        logger.debug('MapRepository', 'District data not cached for $stateId, loading...');
        await _loadDistrictDataForClick(stateId);
      }
      
      if (_currentDistrictGeoData == null) {
        logger.warning('MapRepository', 'No district data available for click detection in $stateId');
        return null;
      }
      
      logger.debug('MapRepository', 'Checking ${_currentDistrictGeoData!.features.length} district features for click detection');
      
      // Use whereType to filter out null features
      for (final feature in _currentDistrictGeoData!.features.whereType<GeoJSONFeature>()) {
        try {
          final geom = feature.geometry;
          if (geom == null) continue;
          
          // Handle both Polygon and MultiPolygon for click detection
          List<List<LatLng>> allPolygonCoords = [];
          
          if (geom is GeoJSONPolygon) {
            if (geom.coordinates.isNotEmpty) {
              final coords = _convertCoordinatesToLatLng(geom.coordinates[0]);
              allPolygonCoords.add(coords);
            }
          } else if (geom is GeoJSONMultiPolygon) {
            for (final polygonCoords in geom.coordinates) {
              if (polygonCoords.isNotEmpty) {
                final coords = _convertCoordinatesToLatLng(polygonCoords[0]);
                allPolygonCoords.add(coords);
              }
            }
          }
          
          // Check if point is inside any of the polygons
          for (final coords in allPolygonCoords) {
            if (_isPointInPolygon(clickPoint, coords)) {
              final properties = feature.properties ?? {};
              
              final result = {
                'id': properties['id'] ?? properties['DISTRICT'] ?? properties['name'] ?? 'unknown',
                'name': properties['name'] ?? properties['DISTRICT'] ?? 'Unknown District',
                'center': _getPolygonCenter(coords),
                'properties': properties,
                'stateId': stateId,
              };
              
              logger.mapEvent('DISTRICT_CLICK_DETECTED', {
                'clickPoint': {'lat': clickPoint.latitude, 'lng': clickPoint.longitude},
                'detectedDistrict': result['name'],
                'districtId': result['id'],
                'stateId': stateId,
                'detectionTimeMs': stopwatch.elapsedMilliseconds,
              });
              
              return result;
            }
          }
        } catch (e) {
          logger.warning('MapRepository', 'Error processing district feature for click detection: $e');
          continue;
        }
      }
      
      logger.debug('MapRepository', 'No district found for click point (${stopwatch.elapsedMilliseconds}ms)');
      return null;
    } catch (e, stackTrace) {
      logger.error('MapRepository', 'Error finding clicked district', e, stackTrace);
      return null;
    } finally {
      stopwatch.stop();
    }
  }

  // Helper method to load district data for click detection
  Future<void> _loadDistrictDataForClick(String stateId) async {
    try {
      String geojsonStr;
      try {
        // Look for state-specific files like "rajasthan.geojson"
        geojsonStr = await rootBundle.loadString('assets/layers/${stateId.toLowerCase()}.geojson');
        logger.debug('MapRepository', 'Successfully loaded district GeoJSON for click detection: $stateId');
      } catch (e) {
        // Fallback: try the old naming convention
        try {
          geojsonStr = await rootBundle.loadString('assets/layers/districts/${stateId}_districts.geojson');
          logger.debug('MapRepository', 'Successfully loaded districts GeoJSON for click detection: $stateId (fallback)');
        } catch (e2) {
          logger.warning('MapRepository', 'District data not available for click detection in state: $stateId');
          return;
        }
      }
      
      final geojson = GeoJSONFeatureCollection.fromJSON(geojsonStr);
      _currentDistrictGeoData = geojson;
      _currentStateId = stateId;
      
      logger.debug('MapRepository', 'Cached district data for click detection: ${geojson.features.length} features for $stateId');
    } catch (e) {
      logger.warning('MapRepository', 'Error loading district data for click detection: $e');
    }
  }

  // Ray casting algorithm to check if point is inside polygon
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int crossings = 0;
    
    for (int i = 0; i < polygon.length - 1; i++) {
      final a = polygon[i];
      final b = polygon[i + 1];
      
      if (((a.latitude <= point.latitude) && (point.latitude < b.latitude)) ||
          ((b.latitude <= point.latitude) && (point.latitude < a.latitude))) {
        
        final intersectionLng = a.longitude + 
            (point.latitude - a.latitude) / (b.latitude - a.latitude) * 
            (b.longitude - a.longitude);
        
        if (point.longitude < intersectionLng) {
          crossings++;
        }
      }
    }
    
    return crossings % 2 == 1;
  }

  // Calculate center of polygon for navigation
  LatLng _getPolygonCenter(List<LatLng> coords) {
    double lat = 0;
    double lng = 0;
    
    for (final coord in coords) {
      lat += coord.latitude;
      lng += coord.longitude;
    }
    
    return LatLng(lat / coords.length, lng / coords.length);
  }

  // Load detailed state data (districts within a state)
  Future<List<Polygon>> loadDistrictPolygons(String stateId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.debug('MapRepository', 'Attempting to load districts for state: $stateId');
      
      // Try to load state-specific district data
      String geojsonStr;
      try {
        // Look for state-specific files like "rajasthan.geojson"
        geojsonStr = await rootBundle.loadString('assets/layers/${stateId.toLowerCase()}.geojson');
        logger.debug('MapRepository', 'Successfully loaded state detail GeoJSON for $stateId');
      } catch (e) {
        // Fallback: try the old naming convention
        try {
          geojsonStr = await rootBundle.loadString('assets/layers/districts/${stateId}_districts.geojson');
          logger.debug('MapRepository', 'Successfully loaded districts GeoJSON for $stateId (fallback)');
        } catch (e2) {
          logger.warning('MapRepository', 'District data not available for state: $stateId');
          return [];
        }
      }
      
      final geojson = GeoJSONFeatureCollection.fromJSON(geojsonStr);
      logger.debug('MapRepository', 'Parsed GeoJSON with ${geojson.features.length} features for $stateId');
      
      final polygons = <Polygon>[];
      int processedFeatures = 0;
      
      // Use whereType to filter out null features
      for (final feature in geojson.features.whereType<GeoJSONFeature>()) {
        try {
          final geom = feature.geometry;
          if (geom == null) continue;
          
          // Handle both Polygon and MultiPolygon geometries
          List<List<LatLng>> allPolygonCoords = [];
          
          if (geom is GeoJSONPolygon) {
            if (geom.coordinates.isNotEmpty) {
              final coords = _convertCoordinatesToLatLng(geom.coordinates[0]);
              if (coords.length >= 3) {
                allPolygonCoords.add(coords);
              }
            }
          } else if (geom is GeoJSONMultiPolygon) {
            // MultiPolygon: coordinates is List<List<List<List<double>>>>
            for (final polygonCoords in geom.coordinates) {
              if (polygonCoords.isNotEmpty) {
                final coords = _convertCoordinatesToLatLng(polygonCoords[0]);
                if (coords.length >= 3) {
                  allPolygonCoords.add(coords);
                }
              }
            }
          }
          
          // Create Flutter polygons from all coordinate sets
          for (final coords in allPolygonCoords) {
            polygons.add(
              Polygon(
                points: coords,
                borderColor: Colors.orange.withValues(alpha: 0.8),
                color: Colors.orange.withValues(alpha: 0.3),
                borderStrokeWidth: 1.5,
              ),
            );
          }
          
          if (allPolygonCoords.isNotEmpty) {
            processedFeatures++;
          }
          
        } catch (e) {
          logger.warning('MapRepository', 'Failed to create polygon from feature: $e');
          continue;
        }
      }
      
      logger.performance('LOAD_DISTRICT_POLYGONS', stopwatch.elapsedMilliseconds, {
        'count': polygons.length,
        'stateId': stateId,
        'processedFeatures': processedFeatures,
      });
      
      logger.info('MapRepository', 'Loaded ${polygons.length} district polygons for $stateId from ${processedFeatures} features');
      return polygons;
    } catch (e, stackTrace) {
      logger.warning('MapRepository', 'District data not available for state: $stateId - $e');
      return [];
    } finally {
      stopwatch.stop();
    }
  }

  // NEW: Load taluk/sub-district data for a specific district
  Future<List<Polygon>> loadTalukPolygons(String districtId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.debug('MapRepository', 'Attempting to load taluks for district: $districtId');
      
      // Try to load district-specific taluk data
      String geojsonStr;
      try {
        // Look for district-specific files like "rajasthan_jhalawar.geojson"
        geojsonStr = await rootBundle.loadString('assets/layers/${districtId.toLowerCase()}.geojson');
        logger.debug('MapRepository', 'Successfully loaded district detail GeoJSON for $districtId');
      } catch (e) {
        // Fallback: try the old naming convention
        try {
          geojsonStr = await rootBundle.loadString('assets/layers/taluks/${districtId}_taluks.geojson');
          logger.debug('MapRepository', 'Successfully loaded taluks GeoJSON for $districtId (fallback)');
        } catch (e2) {
          logger.warning('MapRepository', 'Taluk data not available for district: $districtId');
          return [];
        }
      }
      
      final geojson = GeoJSONFeatureCollection.fromJSON(geojsonStr);
      logger.debug('MapRepository', 'Parsed GeoJSON with ${geojson.features.length} features for $districtId');
      
      final polygons = <Polygon>[];
      int processedFeatures = 0;
      
      // Use whereType to filter out null features
      for (final feature in geojson.features.whereType<GeoJSONFeature>()) {
        try {
          final geom = feature.geometry;
          if (geom == null) continue;
          
          // Handle both Polygon and MultiPolygon geometries
          List<List<LatLng>> allPolygonCoords = [];
          
          if (geom is GeoJSONPolygon) {
            if (geom.coordinates.isNotEmpty) {
              final coords = _convertCoordinatesToLatLng(geom.coordinates[0]);
              if (coords.length >= 3) {
                allPolygonCoords.add(coords);
              }
            }
          } else if (geom is GeoJSONMultiPolygon) {
            // MultiPolygon: coordinates is List<List<List<List<double>>>>
            for (final polygonCoords in geom.coordinates) {
              if (polygonCoords.isNotEmpty) {
                final coords = _convertCoordinatesToLatLng(polygonCoords[0]);
                if (coords.length >= 3) {
                  allPolygonCoords.add(coords);
                }
              }
            }
          }
          
          // Create Flutter polygons from all coordinate sets
          for (final coords in allPolygonCoords) {
            polygons.add(
              Polygon(
                points: coords,
                borderColor: Colors.green.withValues(alpha: 0.8),
                color: Colors.green.withValues(alpha: 0.3),
                borderStrokeWidth: 1.5,
              ),
            );
          }
          
          if (allPolygonCoords.isNotEmpty) {
            processedFeatures++;
          }
          
        } catch (e) {
          logger.warning('MapRepository', 'Failed to create polygon from feature: $e');
          continue;
        }
      }
      
      logger.performance('LOAD_TALUK_POLYGONS', stopwatch.elapsedMilliseconds, {
        'count': polygons.length,
        'districtId': districtId,
        'processedFeatures': processedFeatures,
      });
      
      logger.info('MapRepository', 'Loaded ${polygons.length} taluk polygons for $districtId from ${processedFeatures} features');
      return polygons;
    } catch (e, stackTrace) {
      logger.warning('MapRepository', 'Taluk data not available for district: $districtId - $e');
      return [];
    } finally {
      stopwatch.stop();
    }
  }

  Future<List<Marker>> loadPOIsForRegion(String regionId, String regionType) async {
    try {
      logger.debug('MapRepository', 'Attempting to load POIs for $regionType: $regionId');
      
      final String geojsonStr = 
          await rootBundle.loadString('assets/layers/pois/${regionType}_${regionId}_pois.geojson');
      return [];
    } catch (e) {
      logger.warning('MapRepository', 'POI data not available for $regionType: $regionId');
      return [];
    }
  }

  Future<List<Polyline>> loadRiverLines() async {
    try {
      logger.debug('MapRepository', 'Loading river lines');
      
      final String geojsonStr = 
          await rootBundle.loadString('assets/layers/india_rivers.geojson');
      final geojson = GeoJSONFeatureCollection.fromJSON(geojsonStr);
      
      final lines = <Polyline>[];
      
      // Use whereType to filter out null features
      for (final feature in geojson.features.whereType<GeoJSONFeature>()) {
        final geom = feature.geometry;
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
      
      logger.info('MapRepository', 'Loaded ${lines.length} river lines');
      return lines;
    } catch (e, stackTrace) {
      logger.error('MapRepository', 'Error loading river lines', e, stackTrace);
      return [];
    }
  }

  // NEW: Calculate bounds for a set of coordinates
  Map<String, double> _calculateBounds(List<LatLng> coords) {
    if (coords.isEmpty) {
      return {
        'minLat': 0.0,
        'maxLat': 0.0,
        'minLng': 0.0,
        'maxLng': 0.0,
      };
    }
    
    double minLat = coords.first.latitude;
    double maxLat = coords.first.latitude;
    double minLng = coords.first.longitude;
    double maxLng = coords.first.longitude;
    
    for (final coord in coords) {
      minLat = math.min(minLat, coord.latitude);
      maxLat = math.max(maxLat, coord.latitude);
      minLng = math.min(minLng, coord.longitude);
      maxLng = math.max(maxLng, coord.longitude);
    }
    
    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  // NEW: Get bounds for a specific state
  Future<Map<String, double>?> getStateBounds(String stateId) async {
    try {
      // Load district data to get the state outline
      String geojsonStr;
      try {
        geojsonStr = await rootBundle.loadString('assets/layers/${stateId.toLowerCase()}.geojson');
      } catch (e) {
        try {
          geojsonStr = await rootBundle.loadString('assets/layers/districts/${stateId}_districts.geojson');
        } catch (e2) {
          logger.warning('MapRepository', 'Cannot calculate bounds for $stateId - no data available');
          return null;
        }
      }
      
      final geojson = GeoJSONFeatureCollection.fromJSON(geojsonStr);
      
      double minLat = double.infinity;
      double maxLat = double.negativeInfinity;
      double minLng = double.infinity;
      double maxLng = double.negativeInfinity;
      
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
          for (final coord in coords) {
            minLat = math.min(minLat, coord.latitude);
            maxLat = math.max(maxLat, coord.latitude);
            minLng = math.min(minLng, coord.longitude);
            maxLng = math.max(maxLng, coord.longitude);
          }
        }
      }
      
      if (minLat == double.infinity) return null;
      
      return {
        'minLat': minLat,
        'maxLat': maxLat,
        'minLng': minLng,
        'maxLng': maxLng,
      };
    } catch (e) {
      logger.warning('MapRepository', 'Error calculating bounds for $stateId: $e');
      return null;
    }
  }

  // NEW: Get bounds for a specific district
  Future<Map<String, double>?> getDistrictBounds(String districtId) async {
    try {
      String geojsonStr;
      try {
        geojsonStr = await rootBundle.loadString('assets/layers/${districtId.toLowerCase()}.geojson');
      } catch (e) {
        try {
          geojsonStr = await rootBundle.loadString('assets/layers/taluks/${districtId}_taluks.geojson');
        } catch (e2) {
          logger.warning('MapRepository', 'Cannot calculate bounds for $districtId - no data available');
          return null;
        }
      }
      
      final geojson = GeoJSONFeatureCollection.fromJSON(geojsonStr);
      
      double minLat = double.infinity;
      double maxLat = double.negativeInfinity;
      double minLng = double.infinity;
      double maxLng = double.negativeInfinity;
      
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
          for (final coord in coords) {
            minLat = math.min(minLat, coord.latitude);
            maxLat = math.max(maxLat, coord.latitude);
            minLng = math.min(minLng, coord.longitude);
            maxLng = math.max(maxLng, coord.longitude);
          }
        }
      }
      
      if (minLat == double.infinity) return null;
      
      return {
        'minLat': minLat,
        'maxLat': maxLat,
        'minLng': minLng,
        'maxLng': maxLng,
      };
    } catch (e) {
      logger.warning('MapRepository', 'Error calculating bounds for $districtId: $e');
      return null;
    }
  }
}