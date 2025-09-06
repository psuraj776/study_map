import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/layer_providers.dart';
import '../../../../core/models/layer_models.dart';
import '../../../../core/constants/dev_config.dart';
import '../../../../l10n/app_localizations.dart';

class LayerMenu extends ConsumerWidget {
  const LayerMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMenuVisible = ref.watch(layerMenuVisibilityProvider);
    final layerStates = ref.watch(layerStatesProvider);
    final layerNotifier = ref.read(layerStatesProvider.notifier);

    // Only show the drawer when menu is visible
    if (!isMenuVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 16,
        child: Container(
          width: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.layers,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (DevConfig.isDevelopmentMode) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'DEV MODE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref.read(layerMenuVisibilityProvider.notifier).hide();
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Development Controls (only in dev mode)
              if (DevConfig.isDevelopmentMode) ...[
                Container(
                  color: Colors.orange.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Development Controls',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                layerNotifier.enableAllPremiumForDev();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('All premium features enabled'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('Enable All', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                layerNotifier.simulateFreeUser();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Simulating free user'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('Free User', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],

              // Layer List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: AppLayers.allLayers.length,
                  itemBuilder: (context, index) {
                    final layer = AppLayers.allLayers[index];
                    return _buildLayerTile(context, ref, layer, layerStates, layerNotifier);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayerTile(
    BuildContext context,
    WidgetRef ref,
    LayerInfo layer,
    Map<String, bool> layerStates,
    LayerStatesNotifier layerNotifier,
  ) {
    final isEnabled = layerStates[layer.id] ?? false;
    final isAccessible = layer.isAccessible;

    return Column(
      children: [
        ListTile(
          dense: true,
          leading: Icon(
            layerNotifier.isLayerEffectivelyEnabled(layer.id) 
                ? Icons.visibility 
                : Icons.visibility_off,
            color: layer.isAccessible ? Colors.blue : Colors.grey,
          ),
          title: Text(
            layer.getName(context), // Use getName method
            style: TextStyle(
              color: layer.isAccessible ? Colors.black : Colors.grey,
              fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            layer.getDescription(context), // Use getDescription method
            style: TextStyle(
              color: isAccessible ? Colors.black54 : Colors.grey,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isEnabled,
              onChanged: isAccessible
                  ? (value) => layerNotifier.toggleLayer(layer.id)
                  : null,
              activeColor: Colors.green,
            ),
          ),
          onTap: isAccessible
              ? () => layerNotifier.toggleLayer(layer.id)
              : () {
                  if (!DevConfig.isDevelopmentMode) {
                    _showPremiumDialog(context);
                  }
                },
        ),

        // Sub-layers
        if (layer.subLayers.isNotEmpty && isEnabled) ...[
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: layer.subLayers.map((subLayer) {
                return _buildSubLayerTile(context, ref, subLayer, layerStates, layerNotifier);
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubLayerTile(
    BuildContext context,
    WidgetRef ref,
    LayerInfo subLayer,
    Map<String, bool> layerStates,
    LayerStatesNotifier layerNotifier,
  ) {
    final isEnabled = layerStates[subLayer.id] ?? false;
    final isAccessible = subLayer.isAccessible;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 16, right: 16),
      leading: Icon(
        _getLayerIcon(subLayer.id),
        size: 16,
        color: isAccessible 
            ? (isEnabled ? Colors.green : Colors.grey)
            : Colors.red,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              subLayer.getName(context), // Use getName method instead of .name
              style: TextStyle(
                fontSize: 12,
                color: isAccessible ? Colors.black : Colors.grey,
              ),
            ),
          ),
          if (subLayer.isPremium && DevConfig.isDevelopmentMode) ...[
            const Text(
              'DEV',
              style: TextStyle(
                fontSize: 8,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      trailing: Transform.scale(
        scale: 0.7,
        child: Switch(
          value: isEnabled,
          onChanged: isAccessible
              ? (value) => layerNotifier.toggleLayer(subLayer.id)
              : null,
          activeColor: Colors.green,
        ),
      ),
      onTap: isAccessible
          ? () => layerNotifier.toggleLayer(subLayer.id)
          : null,
    );
  }

  IconData _getLayerIcon(String layerId) {
    switch (layerId) {
      case 'india':
        return Icons.map;
      case 'states':
        return Icons.location_city;
      case 'geography':
        return Icons.terrain;
      case 'geography_rivers':
        return Icons.water;
      case 'geography_mountains':
        return Icons.landscape;
      case 'infrastructure':
        return Icons.business;
      case 'infrastructure_roads':
        return Icons.directions_car;
      case 'infrastructure_railways':
        return Icons.train;
      default:
        return Icons.layers;
    }
  }

  void _showPremiumDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'This feature requires a premium subscription. '
          'Upgrade to access all map layers and features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel), // Use localized text
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to subscription screen
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}