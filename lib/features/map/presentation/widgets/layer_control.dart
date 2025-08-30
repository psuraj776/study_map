import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../domain/models/layer_model.dart';

class LayerControl extends ConsumerWidget {
  const LayerControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, simplified without subscription logic
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          title: const Text('State Boundaries'),
          value: true,
          onChanged: (value) {
            // TODO: Implement layer toggle
          },
        ),
        CheckboxListTile(
          title: const Text('Rivers'),
          value: true,
          onChanged: (value) {
            // TODO: Implement layer toggle
          },
        ),
      ],
    );
  }
}