import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../domain/models/layer_model.dart';

class LayerControl extends ConsumerWidget {
  const LayerControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layers = ref.watch(layersProvider);
    final visibility = ref.watch(layerVisibilityProvider);
    final isPremium = ref.watch(premiumStatusProvider).value ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...layers.map((layer) {
          final bool isVisible = visibility[layer.id] ?? false;
          final bool isAccessible =
              layer.tier == LayerTier.free || isPremium;

          return CheckboxListTile(
            title: Text(layer.name),
            subtitle: layer.tier == LayerTier.premium
                ? const Text('Premium',
                    style: TextStyle(color: Colors.amber))
                : null,
            value: isVisible && isAccessible,
            onChanged: isAccessible
                ? (value) => ref
                    .read(layerVisibilityProvider.notifier)
                    .toggle(layer.id)
                : null,
          );
        }),
        if (!isPremium)
          ElevatedButton(
            onPressed: () {
              // TODO: Implement purchase flow
            },
            child: const Text('Upgrade to Premium'),
          ),
      ],
    );
  }
}