import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

class SecureDeviceService {
  static const String _deviceIdKey = 'active_device';
  final SharedPreferences _prefs;
  final AppLogger _logger = AppLogger.instance;

  SecureDeviceService(this._prefs);

  Future<bool> validateDevice() async {
    try {
      _logger.debug('DeviceService', 'Starting device validation');
      
      final storedDeviceId = _prefs.getString(_deviceIdKey);
      
      if (storedDeviceId == null) {
        _logger.info('DeviceService', 'First time user - registering device');
        // First time user - register device
        await registerDevice();
        return true;
      }
      
      _logger.debug('DeviceService', 'Found stored device ID: $storedDeviceId');
      
      // For this demo, always return true if device ID exists
      // In real app, you'd validate against server
      final isValid = storedDeviceId.isNotEmpty;
      
      _logger.authEvent('DEVICE_VALIDATION', 'Device valid: $isValid');
      
      return isValid;
    } catch (e, stackTrace) {
      _logger.error('DeviceService', 'Error validating device', e, stackTrace);
      print('Error validating device: $e');
      // Return false on error instead of throwing
      return false;
    }
  }

  Future<void> registerDevice() async {
    try {
      _logger.debug('DeviceService', 'Starting device registration');
      
      // Generate a simple device ID for demo
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await _prefs.setString(_deviceIdKey, deviceId);
      
      _logger.info('DeviceService', 'Device registered successfully');
      _logger.authEvent('DEVICE_REGISTRATION', 'Device ID: $deviceId');
      
      print('Device registered with ID: $deviceId');
    } catch (e, stackTrace) {
      _logger.error('DeviceService', 'Error registering device', e, stackTrace);
      print('Error registering device: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      _logger.debug('DeviceService', 'Starting device logout');
      
      await _prefs.remove(_deviceIdKey);
      
      _logger.info('DeviceService', 'Device logout completed');
      _logger.authEvent('DEVICE_LOGOUT', 'Device logged out successfully');
      
      print('Device logged out');
    } catch (e, stackTrace) {
      _logger.error('DeviceService', 'Error during logout', e, stackTrace);
      print('Error during logout: $e');
      rethrow;
    }
  }
}