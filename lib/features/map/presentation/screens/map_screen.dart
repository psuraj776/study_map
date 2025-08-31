import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../../core/providers/app_providers.dart';
import '../widgets/layer_control.dart';
import '../widgets/map_widget.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  @override
  void initState() {
    super.initState();
    final logger = ref.read(loggerProvider);
    logger.info('MapScreen', 'Map screen initialized');
  }

  @override
  Widget build(BuildContext context) {
    final logger = ref.read(loggerProvider);

    logger.debug('MapScreen', 'Building map screen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('India Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: () {
              logger.debug('MapScreen', 'User tapped layers button');
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  logger.debug('MapScreen', 'Showing layer control bottom sheet');
                  return const LayerControl();
                },
              );
            },
          ),
        ],
      ),
      body: const MapWidget(),
    );
  }

  @override
  void dispose() {
    final logger = ref.read(loggerProvider);
    logger.debug('MapScreen', 'Map screen disposed');
    super.dispose();
  }
}