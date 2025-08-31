import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

class LayerControl extends ConsumerWidget {
  const LayerControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final polygons = ref.watch(statePolygonsProvider);
    final isPremium = ref.watch(premiumStatusProvider);

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
            value: true,
            onChanged: (value) {
              // TODO: Implement layer toggle
            },
            secondary: const Icon(Icons.crop_square, color: Colors.blue),
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
            value: false,
            onChanged: !isPremium
                ? null
                : (value) {
                    // TODO: Implement river layer toggle
                  },
            secondary: const Icon(Icons.timeline, color: Colors.cyan),
          ),
          if (!isPremium) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.upgrade, color: Colors.orange),
              title: const Text('Upgrade to Premium'),
              subtitle: const Text('Access all layers and features'),
              onTap: () => _showUpgradeDialog(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
          'Enter activation code to unlock premium features:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _showActivationCodeDialog(context, ref);
            },
            child: const Text('Enter Code'),
          ),
        ],
      ),
    );
  }

  void _showActivationCodeDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final subscriptionService = ref.read(subscriptionServiceProvider);
              await subscriptionService.activatePremium(controller.text);
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