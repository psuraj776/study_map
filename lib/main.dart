import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/app_providers.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/map/presentation/screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
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
      debugShowCheckedModeBanner: false,
      home: Consumer(
        builder: (context, ref, child) {
          final deviceAuth = ref.watch(deviceAuthStateProvider);
          
          return deviceAuth.when(
            data: (isValidDevice) => isValidDevice 
                ? const MapScreen() 
                : const LoginScreen(),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error loading auth state'),
          );
        },
      ),
    );
  }
}
