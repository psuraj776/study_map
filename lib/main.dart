import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/app_providers.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/map/presentation/screens/map_screen.dart';
import 'services/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger first
  final logger = AppLogger.instance;
  await logger.initialize();
  
  logger.info('App', 'Application starting...');
  
  // Initialize SharedPreferences before app starts
  final sharedPreferences = await SharedPreferences.getInstance();
  logger.info('App', 'SharedPreferences initialized');
  
  runApp(
    ProviderScope(
      overrides: [
        // Provide the actual SharedPreferences instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Map App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AppHome(),
    );
  }
}

class AppHome extends ConsumerWidget {
  const AppHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAuth = ref.watch(deviceAuthStateProvider);
    final logger = ref.read(loggerProvider);
    
    return Scaffold(
      body: deviceAuth.when(
        data: (isValidDevice) {
          logger.authEvent('APP_HOME_RENDER', 'Device valid: $isValidDevice');
          return isValidDevice 
              ? const MapScreen() 
              : const LoginScreen();
        },
        loading: () {
          logger.debug('App', 'Loading device auth state...');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        },
        error: (error, stackTrace) {
          logger.error('App', 'Auth state error', error, stackTrace);
          
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${error.toString()}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      logger.info('App', 'User triggered auth state refresh');
                      ref.invalidate(deviceAuthStateProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
