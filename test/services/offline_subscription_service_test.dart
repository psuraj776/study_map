import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/offline_subscription_service.dart';

void main() {
  group('OfflineSubscriptionService Tests', () {
    late OfflineSubscriptionService service;

    setUp(() {
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

      expect(service.isPremiumUser(), true);
    });

    test('activatePremium ignores invalid code', () async {
      final prefs = await SharedPreferences.getInstance();
      service = OfflineSubscriptionService(prefs);

      await service.activatePremium('INVALID_CODE');

      expect(service.isPremiumUser(), false);
    });

    test('deactivatePremium sets premium to false', () async {
      final prefs = await SharedPreferences.getInstance();
      service = OfflineSubscriptionService(prefs);

      // Activate first
      await service.activatePremium('PREMIUM2025');
      expect(service.isPremiumUser(), true);

      // Then deactivate
      await service.deactivatePremium();
      expect(service.isPremiumUser(), false);
    });
  });
}