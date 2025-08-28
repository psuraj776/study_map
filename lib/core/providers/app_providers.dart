import 'package:flutter_riverpod/flutter_riverpod.dart';
// ...existing imports...

// Add all providers from both files here
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final deviceServiceProvider = Provider<SecureDeviceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SecureDeviceService(prefs);
});

final deviceAuthStateProvider = StateNotifierProvider<DeviceAuthNotifier, AsyncValue<bool>>((ref) {
  return DeviceAuthNotifier(ref.watch(deviceServiceProvider));
});

// ...other providers...