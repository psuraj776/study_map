import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/constants/map_constants.dart';

class MapWidget extends ConsumerWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final polygons = ref.watch(statePolygonsProvider);
    //final polylines = ref.watch(riverLinesProvider);

    return FlutterMap(
      options: MapOptions(
        initialCenter: MapConstants.indiaCenter,
        initialZoom: MapConstants.defaultZoom,
        minZoom: MapConstants.minZoom,
        maxZoom: MapConstants.maxZoom,
      ),
      children: [
        // Use OpenStreetMap tiles for now (online)
        // TODO: Replace with MBTiles when package issues are resolved
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.offline_map_app',
        ),
        polygons.when(
          data: (data) => PolygonLayer(polygons: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(),
        ),
        /*
        polylines.when(
          data: (data) => PolylineLayer(polylines: data),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
        */
      ],
    );
  }
}