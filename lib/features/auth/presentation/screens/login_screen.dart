import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_providers.dart';

final layerVisibilityProvider = StateNotifierProvider<LayerVisibilityNotifier, Map<String, bool>>((ref) {
  return LayerVisibilityNotifier();
});

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAuth = ref.watch(deviceAuthStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Device Authorization')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: deviceAuth.when(
            data: (isValidDevice) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isValidDevice ? Icons.verified_user : Icons.no_accounts,
                  size: 48,
                  color: isValidDevice ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  isValidDevice 
                      ? 'Device Authorized'
                      : 'Device Not Authorized',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                if (!isValidDevice)
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(deviceAuthStateProvider.notifier).login()
                        .catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        });
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Authorize This Device'),
                  ),
                if (isValidDevice)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(deviceAuthStateProvider.notifier).logout();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Device logged out successfully')),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${error.toString()}'),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(deviceAuthStateProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LayerVisibilityNotifier extends StateNotifier<Map<String, bool>> {
  LayerVisibilityNotifier() : super({});

  void setLayerVisibility(String layerId, bool isVisible) {
    state = {
      ...state,
      layerId: isVisible,
    };
  }

  bool isLayerVisible(String layerId) {
    return state[layerId] ?? false;
  }
}