import 'package:shared_preferences/shared_preferences.dart';

class SecureDeviceService {
  static const String _deviceIdKey = 'active_device';
  final SharedPreferences _prefs;

  SecureDeviceService(this._prefs);

  Future<bool> validateDevice() async {
    try {
      final storedDeviceId = _prefs.getString(_deviceIdKey);
      
      if (storedDeviceId == null) {
        // First time user - register device
        await registerDevice();
        return true;
      }
      
      // For this demo, always return true if device ID exists
      // In real app, you'd validate against server
      return storedDeviceId.isNotEmpty;
    } catch (e) {
      print('Error validating device: $e');
      // Return false on error instead of throwing
      return false;
    }
  }

  Future<void> registerDevice() async {
    try {
      // Generate a simple device ID for demo
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await _prefs.setString(_deviceIdKey, deviceId);
      print('Device registered with ID: $deviceId');
    } catch (e) {
      print('Error registering device: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _prefs.remove(_deviceIdKey);
      print('Device logged out');
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }
}