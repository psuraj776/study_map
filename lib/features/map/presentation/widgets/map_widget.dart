import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/map_constants.dart';

class MapWidget extends ConsumerWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final polygons = ref.watch(statesProvider);
    final polylines = ref.watch(riversProvider);
    final layerVisibility = ref.watch(layerVisibilityProvider);

    return FlutterMap(
      options: MapOptions(
        initialCenter: MapConstants.indiaCenter,
        initialZoom: MapConstants.defaultZoom,
      ),
      children: [
        MBTilesLayer(
          mbtilesPath: 'assets/basemaps/india_basemap.mbtiles',
        ),
        if (layerVisibility['states'] == true)
          polygons.when(
            data: (data) => PolygonLayer(polygons: data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        if (layerVisibility['rivers'] == true)
          polylines.when(
            data: (data) => PolylineLayer(polylines: data),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
      ],
    );
  }
}