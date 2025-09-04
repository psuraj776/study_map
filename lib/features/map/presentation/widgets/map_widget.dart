import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/layer_providers.dart';
import '../../../../core/models/map_navigation_state.dart';
import '../../../../core/utils/polygon_extensions.dart';
import 'layer_menu.dart';
import 'layer_menu_button.dart';

class MapWidget extends ConsumerStatefulWidget {
  const MapWidget({super.key});

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  late final MapController _mapController;
  MapNavigationState? _previousNavigation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final logger = ref.read(loggerProvider);
    final navigation = ref.watch(mapNavigationProvider);
    final layerStates = ref.watch(layerStatesProvider);
    final layerNotifier = ref.read(layerStatesProvider.notifier);
    
    logger.debug('MapWidget', 'Building map widget for level: ${navigation.level}');
    logger.debug('MapWidget', 'Layer states: $layerStates');

    // Check if navigation changed and animate to new position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_previousNavigation != null && 
          (_previousNavigation!.center != navigation.center || 
           _previousNavigation!.zoom != navigation.zoom)) {
        
        logger.debug('MapWidget', 'Animating to new position: ${navigation.center} at zoom ${navigation.zoom}');
        
        _mapController.move(
          navigation.center, 
          navigation.zoom,
        );
      }
      _previousNavigation = navigation;
    });

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: navigation.center,
            initialZoom: navigation.zoom,
            minZoom: 3.0,
            maxZoom: 18.0,
            onTap: (tapPosition, point) {
              logger.debug('MapWidget', 'Map tap detected at: ${point.latitude}, ${point.longitude}');
              _handleMapTap(context, ref, point, navigation);
            },
          ),
          children: [
            // Base OSM Tile Layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.offline_map_app',
              maxZoom: 18,
              maxNativeZoom: 18,
              retinaMode: false,
              tileSize: 256,
              keepBuffer: 2,
              panBuffer: 1,
              errorTileCallback: (tile, error, stackTrace) {
                logger.warning('MapWidget', 'Failed to load tile: $error');
              },
            ),
            
            // INDIA LAYER (Always enabled - Country boundaries)
            if (layerNotifier.isLayerEffectivelyEnabled('india'))
              _buildIndiaLayer(ref, logger),
            
            // STATES LAYER (Based on toggle)
            if (layerNotifier.isLayerEffectivelyEnabled('states'))
              _buildStatesLayer(ref, logger, navigation),
            
            // GEOGRAPHY LAYERS
            if (layerNotifier.isLayerEffectivelyEnabled('geography')) ...[
              // Rivers sub-layer
              if (layerNotifier.isLayerEffectivelyEnabled('geography_rivers'))
                _buildRiversLayer(ref, logger, navigation),
            ],
            
            // Current level polygons (for navigation - districts/taluks)
            _buildNavigationPolygons(ref, logger, navigation),
          ],
        ),
        
        // Layer Menu Button (top-right)
        const LayerMenuButton(),
        
        // Layer Menu Drawer
        const LayerMenu(),
        
        // Breadcrumb Navigation (top-left)
        Positioned(
          top: 10,
          left: 10,
          child: _buildBreadcrumb(context, ref, navigation),
        ),
        
        // Tile source indicator (bottom-left)
        Positioned(
          bottom: 10,
          left: 10,
          child: _buildTileSourceIndicator(),
        ),
        
        // Debug info (top-left, below breadcrumb)
        Positioned(
          top: 120,
          left: 10,
          child: _buildDebugInfo(ref, navigation, layerStates),
        ),
      ],
    );
  }

  // Build India country boundary layer
  Widget _buildIndiaLayer(WidgetRef ref, logger) {
    return FutureBuilder<List<Polygon>>(
      future: _loadIndiaPolygons(ref, logger),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          logger.debug('MapWidget', 'Rendering India layer with ${snapshot.data!.length} polygons');
          return PolygonLayer(
            polygons: snapshot.data!,
          );
        } else if (snapshot.hasError) {
          logger.error('MapWidget', 'Error loading India layer: ${snapshot.error}');
        }
        return const SizedBox();
      },
    );
  }

  // Build States layer
  Widget _buildStatesLayer(WidgetRef ref, logger, MapNavigationState navigation) {
    // Only show states layer at country level
    if (navigation.level != MapLevel.country) {
      return const SizedBox();
    }

    return FutureBuilder<List<Polygon>>(
      future: _loadStatePolygons(ref, logger),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          logger.debug('MapWidget', 'Rendering States layer with ${snapshot.data!.length} polygons');
          return PolygonLayer(
            polygons: snapshot.data!,
          );
        } else if (snapshot.hasError) {
          logger.error('MapWidget', 'Error loading States layer: ${snapshot.error}');
        }
        return const SizedBox();
      },
    );
  }

  // Build Rivers layer
  Widget _buildRiversLayer(WidgetRef ref, logger, MapNavigationState navigation) {
    // Only show rivers in specific states that have data
    if (navigation.level == MapLevel.state && navigation.regionId == 'rajasthan') {
      return FutureBuilder<List<Polyline>>(
        future: _loadRiverLines(ref, logger, navigation.regionId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            logger.debug('MapWidget', 'Rendering Rivers layer with ${snapshot.data!.length} polylines');
            return PolylineLayer(
              polylines: snapshot.data!,
            );
          } else if (snapshot.hasError) {
            logger.error('MapWidget', 'Error loading Rivers layer: ${snapshot.error}');
          }
          return const SizedBox();
        },
      );
    }
    return const SizedBox();
  }

  // Build navigation polygons (for current level navigation)
  Widget _buildNavigationPolygons(WidgetRef ref, logger, MapNavigationState navigation) {
    // Only show navigation polygons for district and taluk levels
    if (navigation.level != MapLevel.district && navigation.level != MapLevel.taluk) {
      return const SizedBox();
    }

    // Use the provider from app_providers.dart (no conflict now)
    final polygons = ref.watch(currentLevelPolygonsProvider);
    
    return polygons.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox();
        
        logger.debug('MapWidget', 'Rendering navigation polygons: ${data.length}');
        return PolygonLayer(
          polygons: data.map((polygon) => polygon.copyWith(
            color: Colors.orange.withOpacity(0.3),
            borderColor: Colors.orange,
            borderStrokeWidth: 1.0,
          )).toList(),
        );
      },
      loading: () => const SizedBox(), // Don't show loading for navigation polygons
      error: (error, stackTrace) {
        logger.error('MapWidget', 'Error rendering navigation polygons: $error', stackTrace);
        return const SizedBox();
      },
    );
  }

  // Load India country boundaries
  Future<List<Polygon>> _loadIndiaPolygons(WidgetRef ref, logger) async {
    try {
      logger.debug('MapWidget', 'Loading India country boundaries');
      final repository = ref.read(mapRepositoryProvider);
      
      final polygons = await repository.loadCountryPolygons();
      logger.info('MapWidget', 'Loaded ${polygons.length} India country polygons');
      return polygons;
    } catch (e) {
      logger.warning('MapWidget', 'Failed to load India polygons: $e');
      return [];
    }
  }

  // Load State boundaries
  Future<List<Polygon>> _loadStatePolygons(WidgetRef ref, logger) async {
    try {
      logger.debug('MapWidget', 'Loading State boundaries');
      final repository = ref.read(mapRepositoryProvider);
      
      final polygons = await repository.loadStatePolygons();
      logger.info('MapWidget', 'Loaded ${polygons.length} state polygons');
      return polygons;
    } catch (e) {
      logger.error('MapWidget', 'Failed to load state polygons: $e');
      return [];
    }
  }

  // Load River lines
  Future<List<Polyline>> _loadRiverLines(WidgetRef ref, logger, String stateId) async {
    try {
      logger.debug('MapWidget', 'Loading Rivers for state: $stateId');
      final repository = ref.read(mapRepositoryProvider);
      
      final rivers = await repository.loadRiverLines(stateId);
      logger.info('MapWidget', 'Loaded ${rivers.length} river polylines for $stateId');
      return rivers;
    } catch (e) {
      logger.error('MapWidget', 'Failed to load river lines for $stateId: $e');
      return [];
    }
  }

  Widget _buildTileSourceIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'OSM + Layers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfo(WidgetRef ref, MapNavigationState navigation, Map<String, bool> layerStates) {
    final layerNotifier = ref.read(layerStatesProvider.notifier);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debug Info:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            'Level: ${navigation.level.toString().split('.').last}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'Region: ${navigation.regionName}',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          const SizedBox(height: 4),
          const Text(
            'Active Layers:',
            style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 10),
          ),
          ...layerStates.entries.where((entry) => layerNotifier.isLayerEffectivelyEnabled(entry.key)).map(
            (entry) => Text(
              '• ${entry.key}',
              style: const TextStyle(color: Colors.green, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMapTap(BuildContext context, WidgetRef ref, LatLng point, MapNavigationState navigation) async {
    final logger = ref.read(loggerProvider);
    
    try {
      logger.debug('MapWidget', 'Processing map tap at: ${point.latitude}, ${point.longitude}');
      
      switch (navigation.level) {
        case MapLevel.country:
          await _handleCountryLevelTap(context, ref, point);
          break;
        case MapLevel.state:
          await _handleStateLevelTap(context, ref, point, navigation.regionId);
          break;
        case MapLevel.district:
          await _handleDistrictLevelTap(context, ref, point, navigation.regionId);
          break;
        default:
          logger.debug('MapWidget', 'No tap handler for level: ${navigation.level}');
      }
    } catch (e, stackTrace) {
      logger.error('MapWidget', 'Error handling map tap: $e', stackTrace);
    }
  }

  Future<void> _handleCountryLevelTap(BuildContext context, WidgetRef ref, LatLng point) async {
    final logger = ref.read(loggerProvider);
    final repository = ref.read(mapRepositoryProvider);
    
    final stateData = await repository.findClickedState(point);
    if (stateData != null && mounted) {
      _showStateDialog(context, ref, stateData);
    }
  }

  Future<void> _handleStateLevelTap(BuildContext context, WidgetRef ref, LatLng point, String stateId) async {
    final logger = ref.read(loggerProvider);
    final repository = ref.read(mapRepositoryProvider);
    
    final districtData = await repository.findClickedDistrict(point, stateId);
    if (districtData != null && mounted) {
      _showDistrictDialog(context, ref, districtData);
    }
  }

  Future<void> _handleDistrictLevelTap(BuildContext context, WidgetRef ref, LatLng point, String districtId) async {
    final logger = ref.read(loggerProvider);
    logger.debug('MapWidget', 'District level tap - showing info for: $districtId');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tapped in district: $districtId'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _showStateDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> stateData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${stateData['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('State ID: ${stateData['id']}'),
            const SizedBox(height: 8),
            Text('Offline Data: ${stateData['hasOfflineData'] ? 'Available' : 'Not Available'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(mapNavigationProvider.notifier).navigateToState(
                stateData['id'],
                stateData['name'],
                stateData['center'], // Add the missing center parameter
              );
            },
            child: const Text('Explore'),
          ),
        ],
      ),
    );
  }

  void _showDistrictDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> districtData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${districtData['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('District ID: ${districtData['id']}'),
            const SizedBox(height: 8),
            Text('Offline Data: ${districtData['hasOfflineData'] ? 'Available' : 'Not Available'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(mapNavigationProvider.notifier).navigateToDistrict(
                districtData['id'],
                districtData['name'],
                districtData['center'], // Add the missing center parameter
              );
            },
            child: const Text('Explore'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, WidgetRef ref, MapNavigationState navigation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (navigation.breadcrumb.length > 1)
            GestureDetector(
              onTap: () {
                ref.read(mapNavigationProvider.notifier).goBack();
              },
              child: const Icon(Icons.arrow_back, size: 16),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ref.read(mapNavigationProvider.notifier).navigateHome();
            },
            child: const Icon(Icons.home, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            navigation.breadcrumb.join(' > '),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}