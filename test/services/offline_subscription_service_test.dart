import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/offline_subscription_service.dart';

void main() {
  group('OfflineSubscriptionService Tests', () {
    late OfflineSubscriptionService service;

    setUp(() {
      // Use SharedPreferences mock instead of mockito
      SharedPreferences.setMockInitialValues({});
    });

    test('isPremiumUser returns false by default', () async {
      final prefs = await SharedPreferences.getInstance();
      service = OfflineSubscriptionService(prefs);

      final result = service.isPremiumUser();

      expect(result, false);
    });

    test('isPremiumUser returns true when premium is active', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', true);
      service = OfflineSubscriptionService(prefs);

      final result = service.isPremiumUser();

      expect(result, true);
    });

    test('activatePremium works with valid code', () async {
      final prefs = await SharedPreferences.getInstance();
      service = OfflineSubscriptionService(prefs);

      await service.activatePremium('PREMIUM2025');

      expect(prefs.getBool('is_premium'), true);
    });

    test('activatePremium ignores invalid code', () async {
      final prefs = await SharedPreferences.getInstance();
      service = OfflineSubscriptionService(prefs);

      await service.activatePremium('INVALID_CODE');

      expect(prefs.getBool('is_premium'), null); // Should remain unchanged
    });

    test('deactivatePremium sets premium to false', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', true); // Set it to true first
      service = OfflineSubscriptionService(prefs);

      await service.deactivatePremium();

      expect(prefs.getBool('is_premium'), false);
    });

    test('activatePremium works with multiple valid codes', () async {
      final prefs = await SharedPreferences.getInstance();
      service = OfflineSubscriptionService(prefs);

      // Test different valid codes
      await service.activatePremium('TRIAL2025');
      expect(prefs.getBool('is_premium'), true);

      await prefs.setBool('is_premium', false); // Reset

      await service.activatePremium('STUDENT2025');
      expect(prefs.getBool('is_premium'), true);
    });
  });
}