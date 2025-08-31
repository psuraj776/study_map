import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/models/map_navigation_state.dart';

class MapWidget extends ConsumerWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = ref.watch(mapNavigationProvider);
    final polygons = ref.watch(currentLevelPolygonsProvider);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: navigation.center,
            initialZoom: navigation.zoom,
            minZoom: 3.0,
            maxZoom: 18.0,
            onTap: (tapPosition, point) {
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
                if (data.isEmpty && navigation.level != MapLevel.country) {
                  // Show a message when no data is available for current level
                  return const SizedBox();
                }
                return PolygonLayer(polygons: data);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.white,
                ),
              ),
              error: (error, _) => const SizedBox(),
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
      ],
    );
  }

  Widget _buildDataIndicator(WidgetRef ref, MapNavigationState navigation) {
    final polygons = ref.watch(currentLevelPolygonsProvider);
    
    return polygons.when(
      data: (data) {
        if (data.isEmpty) {
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

  void _handleMapTap(BuildContext context, WidgetRef ref, LatLng point, MapNavigationState navigation) {
    // Only allow navigation from country level since that's where you have data
    switch (navigation.level) {
      case MapLevel.country:
        // Simulate clicking on a state - in reality, you'd do spatial query
        ref.read(mapNavigationProvider.notifier).navigateToState(
          'test_state', 
          'Test State', 
          point
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigated to state level (demo - no data available)'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      default:
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
              onTap: () => ref.read(mapNavigationProvider.notifier).goBack(),
              child: const Icon(Icons.arrow_back, size: 16),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.read(mapNavigationProvider.notifier).navigateHome(),
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
}