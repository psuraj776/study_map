import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';

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
                    onPressed: () async {
                      final deviceService = ref.read(deviceServiceProvider);
                      await deviceService.registerDevice();
                      ref.invalidate(deviceAuthStateProvider);
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Authorize This Device'),
                  ),
                if (isValidDevice)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final deviceService = ref.read(deviceServiceProvider);
                      await deviceService.logout();
                      ref.invalidate(deviceAuthStateProvider);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('Error: ${error.toString()}'),
          ),
        ),
      ),
    );
  }
}