import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/layer_providers.dart';

class LayerMenuButton extends ConsumerWidget {
  const LayerMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMenuVisible = ref.watch(layerMenuVisibilityProvider);

    return Positioned(
      top: 40,
      right: 10,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        onPressed: () {
          ref.read(layerMenuVisibilityProvider.notifier).toggle();
        },
        child: AnimatedRotation(
          turns: isMenuVisible ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.menu),
        ),
      ),
    );
  }
}