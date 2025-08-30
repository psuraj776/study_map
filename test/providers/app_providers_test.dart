import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/core/providers/app_providers.dart';
import '../../lib/services/secure_device_service.dart';

// Mock classes would be imported from previous test files

void main() {
  group('App Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      container.dispose();
    });

    test('deviceServiceProvider creates SecureDeviceService', () async {
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final service = container.read(deviceServiceProvider);
      
      expect(service, isA<SecureDeviceService>());
    });

    test('deviceAuthStateProvider validates device', () async {
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final authState = container.read(deviceAuthStateProvider);
      
      expect(authState, isA<AsyncValue<bool>>());
    });
  });
}