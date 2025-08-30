import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/services/secure_device_service.dart';

void main() {
  group('SecureDeviceService Tests', () {
    late SecureDeviceService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('validateDevice returns true for first time user', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SecureDeviceService(prefs);

      final result = await service.validateDevice();

      expect(result, true);
      // Verify device ID was stored
      expect(prefs.getString('active_device'), isNotNull);
    });

    test('validateDevice returns true for same device (simulated)', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SecureDeviceService(prefs);

      // First call should register the device
      await service.validateDevice();
      final firstDeviceId = prefs.getString('active_device');

      // Second call should validate successfully (same device)
      final result = await service.validateDevice();

      expect(result, true);
      expect(prefs.getString('active_device'), firstDeviceId);
    });

    test('registerDevice stores device ID', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SecureDeviceService(prefs);

      await service.registerDevice();

      expect(prefs.getString('active_device'), isNotNull);
    });

    test('logout removes device ID', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SecureDeviceService(prefs);

      // First register a device
      await service.registerDevice();
      expect(prefs.getString('active_device'), isNotNull);

      // Then logout
      await service.logout();
      expect(prefs.getString('active_device'), isNull);
    });

    test('multiple logout calls are safe', () async {
      final prefs = await SharedPreferences.getInstance();
      service = SecureDeviceService(prefs);

      await service.logout();
      await service.logout(); // Should not throw

      expect(prefs.getString('active_device'), isNull);
    });
  });
}