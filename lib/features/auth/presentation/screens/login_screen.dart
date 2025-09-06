import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.read(loggerProvider);
    final deviceAuth = ref.watch(deviceAuthStateProvider);
    final l10n = AppLocalizations.of(context)!;

    logger.debug('LoginScreen', 'Building login screen');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deviceAuthorization)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: deviceAuth.when(
            data: (isValidDevice) {
              logger.debug('LoginScreen', 'Device validation result: $isValidDevice');
              
              return Column(
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
                        ? l10n.deviceAuthorized
                        : l10n.deviceNotAuthorized,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  if (!isValidDevice)
                    ElevatedButton.icon(
                      onPressed: () async {
                        logger.info('LoginScreen', 'User attempting device registration');
                        
                        final deviceService = ref.read(deviceServiceProvider);
                        await deviceService.registerDevice();
                        ref.invalidate(deviceAuthStateProvider);
                        
                        logger.info('LoginScreen', 'Device registration completed');
                      },
                      icon: const Icon(Icons.login),
                      label: Text(l10n.authorizeThisDevice),
                    ),
                  if (isValidDevice)
                    ElevatedButton.icon(
                      onPressed: () async {
                        logger.info('LoginScreen', 'User logging out');
                        
                        final deviceService = ref.read(deviceServiceProvider);
                        await deviceService.logout();
                        ref.invalidate(deviceAuthStateProvider);
                        
                        logger.info('LoginScreen', 'User logout completed');
                      },
                      icon: const Icon(Icons.logout),
                      label: Text(l10n.logout),
                    ),
                ],
              );
            },
            loading: () {
              logger.debug('LoginScreen', 'Loading device auth state');
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.loading),
                ],
              );
            },
            error: (error, stackTrace) {
              logger.error('LoginScreen', 'Error in device auth: $error', stackTrace);
              return Text('${l10n.error}: ${error.toString()}');
            },
          ),
        ),
      ),
    );
  }
}