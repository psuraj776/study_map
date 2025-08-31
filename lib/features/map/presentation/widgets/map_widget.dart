import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/models/map_navigation_state.dart';

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
    final polygons = ref.watch(currentLevelPolygonsProvider);
    
    logger.debug('MapWidget', 'Building map widget for level: ${navigation.level}');

    // Check if navigation changed and animate to new position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_previousNavigation != null && 
          (_previousNavigation!.center != navigation.center || 
           _previousNavigation!.zoom != navigation.zoom)) {
        
        logger.debug('MapWidget', 'Animating to new position: ${navigation.center} at zoom ${navigation.zoom}');
        
        // Use animatedMove for smooth transition
        _mapController.move(
          navigation.center, 
          navigation.zoom,
        );
        
        // Alternative: If you want even smoother animation, you can use:
        // _mapController.animatedMove(navigation.center, navigation.zoom, 
        //   duration: const Duration(milliseconds: 800));
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
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.offline_map_app',
            ),
            polygons.when(
              data: (data) {
                logger.debug('MapWidget', 'Rendering ${data.length} polygons');
                print('Rendering ${data.length} polygons');
                if (data.isEmpty && navigation.level != MapLevel.country) {
                  logger.warning('MapWidget', 'No polygons to render for level: ${navigation.level}');
                  return const SizedBox();
                }
                logger.info('MapWidget', 'Successfully rendered ${data.length} polygons');
                return PolygonLayer(polygons: data);
              },
              loading: () {
                logger.debug('MapWidget', 'Loading polygons...');
                return const Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.white,
                  ),
                );
              },
              error: (error, stackTrace) {
                logger.error('MapWidget', 'Error rendering polygons', error, stackTrace);
                print('Error rendering polygons: $error');
                return const SizedBox();
              },
            ),
          ],
        ),
        // Breadcrumb Navigation
        Positioned(
          top: 10,
          left: 10,
          child: _buildBreadcrumb(context, ref, navigation),
        ),
        // Data availability indicator
        if (navigation.level != MapLevel.country)
          Positioned(
            bottom: 10,
            right: 10,
            child: _buildDataIndicator(ref, navigation),
          ),
        // Debug info
        Positioned(
          top: 60,
          left: 10,
          child: _buildDebugInfo(ref, navigation),
        ),
      ],
    );
  }

  Widget _buildDebugInfo(WidgetRef ref, MapNavigationState navigation) {
    final logger = ref.read(loggerProvider);
    final polygons = ref.watch(currentLevelPolygonsProvider);
    final isStateLayerVisible = ref.watch(stateLayerVisibilityProvider);
    
    logger.debug('MapWidget', 'Building debug info panel');
    
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'Level: ${navigation.level.toString().split('.').last}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Region: ${navigation.regionName}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'Zoom: ${navigation.zoom.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            'State Layer: ${isStateLayerVisible ? "ON" : "OFF"}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          polygons.when(
            data: (data) => Text(
              'Polygons: ${data.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            loading: () => const Text(
              'Loading polygons...',
              style: TextStyle(color: Colors.yellow, fontSize: 12),
            ),
            error: (error, __) => Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataIndicator(WidgetRef ref, MapNavigationState navigation) {
    final logger = ref.read(loggerProvider);
    final polygons = ref.watch(currentLevelPolygonsProvider);
    
    logger.debug('MapWidget', 'Building data indicator for level: ${navigation.level}');
    
    return polygons.when(
      data: (data) {
        if (data.isEmpty) {
          logger.info('MapWidget', 'Showing data unavailable indicator');
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Detailed data not available for ${navigation.level.toString().split('.').last}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox();
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  void _handleMapTap(BuildContext context, WidgetRef ref, LatLng point, MapNavigationState navigation) async {
    final logger = ref.read(loggerProvider);
    
    logger.mapEvent('MAP_TAP', {
      'latitude': point.latitude,
      'longitude': point.longitude,
      'currentLevel': navigation.level.name,
      'currentRegion': navigation.regionName,
    });
    
    print('Map tapped at: ${point.latitude}, ${point.longitude}');
    
    // Handle different levels of map interaction
    if (navigation.level == MapLevel.country) {
      // Country level - detect states
      logger.debug('MapWidget', 'Processing state detection for country level tap');
      
      try {
        // Show loading indicator
        logger.debug('MapWidget', 'Showing loading indicator for state detection');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Detecting state...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );

        final repository = ref.read(mapRepositoryProvider);
        final clickedState = await repository.findClickedState(point);
        
        // Clear the loading snackbar
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        
        if (clickedState != null) {
          logger.info('MapWidget', 'State detected: ${clickedState['name']}');
          print('State detected: ${clickedState['name']}');
          // Show state info dialog
          _showStateDialog(context, ref, clickedState);
        } else {
          logger.warning('MapWidget', 'No state detected at location: ${point.latitude}, ${point.longitude}');
          print('No state detected at this location');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tapped: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)} (No state detected)',
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e, stackTrace) {
        logger.error('MapWidget', 'Error in state detection', e, stackTrace);
        print('Error in state detection: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error detecting state: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else if (navigation.level == MapLevel.state) {
      // State level - detect districts
      logger.debug('MapWidget', 'Processing district detection for state level tap');
      
      try {
        // Show loading indicator
        logger.debug('MapWidget', 'Showing loading indicator for district detection');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Detecting district...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );

        final repository = ref.read(mapRepositoryProvider);
        final clickedDistrict = await repository.findClickedDistrict(point, navigation.regionId);
        
        // Clear the loading snackbar
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        
        if (clickedDistrict != null) {
          logger.info('MapWidget', 'District detected: ${clickedDistrict['name']}');
          print('District detected: ${clickedDistrict['name']}');
          // Show district info dialog
          _showDistrictDialog(context, ref, clickedDistrict);
        } else {
          logger.warning('MapWidget', 'No district detected at location: ${point.latitude}, ${point.longitude}');
          print('No district detected at this location');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tapped: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)} (No district detected)',
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e, stackTrace) {
        logger.error('MapWidget', 'Error in district detection', e, stackTrace);
        print('Error in district detection: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error detecting district: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      logger.debug('MapWidget', 'Showing coordinates for ${navigation.level.name} level tap');
      // For other levels, just show coordinates
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tapped: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showStateDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> stateInfo) {
    final logger = ref.read(loggerProvider);
    
    logger.info('MapWidget', 'Showing state dialog for: ${stateInfo['name']}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stateInfo['name'] ?? 'Unknown State',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('State ID: ${stateInfo['id'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text(
              'Center: ${(stateInfo['center'] as LatLng).latitude.toStringAsFixed(4)}, '
              '${(stateInfo['center'] as LatLng).longitude.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 8),
            Text('Properties: ${stateInfo['properties']}'),
            const SizedBox(height: 16),
            const Text(
              'Would you like to navigate to this state?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              logger.debug('MapWidget', 'User cancelled state navigation');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              logger.navigationEvent(
                'India (country)',
                '${stateInfo['name']} (state)',
                'user_dialog_selection'
              );
              
              // Navigate to the clicked state
              ref.read(mapNavigationProvider.notifier).navigateToState(
                stateInfo['id'] ?? 'unknown',
                stateInfo['name'] ?? 'Unknown State',
                stateInfo['center'] as LatLng,
              );
              
              Navigator.of(context).pop();
              
              logger.info('MapWidget', 'User navigated to state: ${stateInfo['name']}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigated to ${stateInfo['name']}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.navigate_next),
            label: const Text('Navigate'),
          ),
        ],
      ),
    );
  }

  // NEW: Show district dialog
  void _showDistrictDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> districtInfo) {
    final logger = ref.read(loggerProvider);
    
    logger.info('MapWidget', 'Showing district dialog for: ${districtInfo['name']}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_city, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                districtInfo['name'] ?? 'Unknown District',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('District ID: ${districtInfo['id'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('State: ${districtInfo['stateId'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text(
              'Center: ${(districtInfo['center'] as LatLng).latitude.toStringAsFixed(4)}, '
              '${(districtInfo['center'] as LatLng).longitude.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 8),
            Text('Properties: ${districtInfo['properties']}'),
            const SizedBox(height: 16),
            const Text(
              'Would you like to navigate to this district?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              logger.debug('MapWidget', 'User cancelled district navigation');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              logger.navigationEvent(
                '${districtInfo['stateId']} (state)',
                '${districtInfo['name']} (district)',
                'user_dialog_selection'
              );
              
              // Create district ID in format: stateid_districtname
              final stateId = districtInfo['stateId'] ?? 'unknown';
              final districtName = districtInfo['name'] ?? 'Unknown District';
              final districtId = '${stateId.toLowerCase()}_${districtName.toLowerCase().replaceAll(' ', '')}';
              
              // Navigate to the clicked district
              ref.read(mapNavigationProvider.notifier).navigateToDistrict(
                districtId,
                districtName,
                districtInfo['center'] as LatLng,
              );
              
              Navigator.of(context).pop();
              
              logger.info('MapWidget', 'User navigated to district: ${districtInfo['name']}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigated to $districtName'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.navigate_next),
            label: const Text('Navigate'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, WidgetRef ref, MapNavigationState navigation) {
    final logger = ref.read(loggerProvider);
    
    logger.debug('MapWidget', 'Building breadcrumb: ${navigation.breadcrumb.join(' > ')}');
    
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
                logger.debug('MapWidget', 'User tapped back button');
                ref.read(mapNavigationProvider.notifier).goBack();
              },
              child: const Icon(Icons.arrow_back, size: 16),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              logger.debug('MapWidget', 'User tapped home button');
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