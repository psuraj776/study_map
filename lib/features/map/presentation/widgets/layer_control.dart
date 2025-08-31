import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

class LayerControl extends ConsumerWidget {
  const LayerControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.read(loggerProvider);
    final isPremium = ref.watch(premiumStatusProvider);
    final isStateLayerVisible = ref.watch(stateLayerVisibilityProvider);
    final isRiverLayerVisible = ref.watch(riverLayerVisibilityProvider);

    logger.debug('LayerControl', 'Building layer control panel');
    logger.debug('LayerControl', 'Premium status: $isPremium, State layer: $isStateLayerVisible, River layer: $isRiverLayerVisible');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Map Layers',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('State Boundaries'),
            subtitle: const Text('Area Layer'),
            value: isStateLayerVisible,
            onChanged: (value) {
              logger.layerEvent('TOGGLE', 'State Boundaries', value ?? false);
              
              // Toggle state layer visibility
              ref.read(stateLayerVisibilityProvider.notifier).state = value ?? false;
              
              logger.info('LayerControl', 'State boundaries ${value == true ? "enabled" : "disabled"}');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value == true 
                        ? 'State boundaries enabled' 
                        : 'State boundaries disabled',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            secondary: Icon(
              Icons.crop_square, 
              color: isStateLayerVisible ? Colors.blue : Colors.grey,
            ),
          ),
          CheckboxListTile(
            title: const Text('Rivers'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Line Layer'),
                if (!isPremium)
                  const Text(
                    'Premium Feature',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
              ],
            ),
            value: isRiverLayerVisible,
            onChanged: !isPremium
                ? (value) {
                    logger.warning('LayerControl', 'User attempted to toggle rivers without premium');
                  }
                : (value) {
                    logger.layerEvent('TOGGLE', 'Rivers', value ?? false);
                    
                    // Toggle river layer visibility
                    ref.read(riverLayerVisibilityProvider.notifier).state = value ?? false;
                    
                    logger.info('LayerControl', 'Rivers ${value == true ? "enabled" : "disabled"} (no data available yet)');
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value == true 
                              ? 'Rivers enabled (no data available yet)' 
                              : 'Rivers disabled',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
            secondary: Icon(
              Icons.timeline, 
              color: isRiverLayerVisible && isPremium ? Colors.cyan : Colors.grey,
            ),
          ),
          if (!isPremium) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.upgrade, color: Colors.orange),
              title: const Text('Upgrade to Premium'),
              subtitle: const Text('Access all layers and features'),
              onTap: () {
                logger.info('LayerControl', 'User tapped upgrade to premium');
                _showUpgradeDialog(context, ref);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, WidgetRef ref) {
    final logger = ref.read(loggerProvider);
    
    logger.debug('LayerControl', 'Showing upgrade dialog');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
          'Enter activation code to unlock premium features:',
        ),
        actions: [
          TextButton(
            onPressed: () {
              logger.debug('LayerControl', 'User cancelled upgrade dialog');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              logger.debug('LayerControl', 'User proceeding to activation code entry');
              _showActivationCodeDialog(context, ref);
            },
            child: const Text('Enter Code'),
          ),
        ],
      ),
    );
  }

  void _showActivationCodeDialog(BuildContext context, WidgetRef ref) {
    final logger = ref.read(loggerProvider);
    final controller = TextEditingController();
    
    logger.debug('LayerControl', 'Showing activation code dialog');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activation Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter PREMIUM2025',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              logger.debug('LayerControl', 'User cancelled activation code entry');
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final code = controller.text;
              logger.info('LayerControl', 'User attempting premium activation with code: $code');
              
              final subscriptionService = ref.read(subscriptionServiceProvider);
              await subscriptionService.activatePremium(code);
              
              if (code == 'PREMIUM2025') {
                logger.info('LayerControl', 'Premium activation successful');
              } else {
                logger.warning('LayerControl', 'Premium activation failed - invalid code');
              }
              
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Premium activated!')),
                );
              }
            },
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }
}