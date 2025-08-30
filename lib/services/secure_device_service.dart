import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SecureDeviceService {
  static const String _deviceKey = 'active_device';
  final SharedPreferences _prefs;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  SecureDeviceService(this._prefs);

  Future<String> _getDeviceId() async {
    final deviceInfo = await _deviceInfo.androidInfo;
    return deviceInfo.id;
  }

  Future<bool> validateDevice() async {
    final deviceId = await _getDeviceId();
    final storedDevice = _prefs.getString(_deviceKey);
    
    if (storedDevice == null) {
      await _prefs.setString(_deviceKey, deviceId);
      return true;
    }

    return storedDevice == deviceId;
  }

  Future<void> registerDevice() async {
    final deviceId = await _getDeviceId();
    await _prefs.setString(_deviceKey, deviceId);
  }

  Future<void> logout() async {
    await _prefs.remove(_deviceKey);
  }
}