import 'package:shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';

class SecureDeviceService {
  static const String _deviceKey = 'active_device';
  static const String _lastLogoutKey = 'last_logout_timestamp';
  final SharedPreferences _prefs;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  SecureDeviceService(this._prefs);

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = await _deviceInfo.androidInfo;
    return {
      'id': deviceInfo.id,
      'brand': deviceInfo.brand,
      'model': deviceInfo.model,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<bool> validateDevice() async {
    final currentDevice = await _getDeviceInfo();
    final storedDeviceJson = _prefs.getString(_deviceKey);
    
    if (storedDeviceJson == null) {
      await _registerDevice(currentDevice);
      return true;
    }

    final storedDevice = json.decode(storedDeviceJson);
    return storedDevice['id'] == currentDevice['id'];
  }

  Future<void> _registerDevice(Map<String, dynamic> deviceInfo) async {
    await _prefs.setString(_deviceKey, json.encode(deviceInfo));
  }

  Future<bool> logout() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setString(_lastLogoutKey, timestamp.toString());
    return await _prefs.remove(_deviceKey);
  }

  Future<bool> login() async {
    final currentDevice = await _getDeviceInfo();
    final lastLogoutStr = _prefs.getString(_lastLogoutKey);
    
    // Enforce cooldown period between device switches (e.g., 5 minutes)
    if (lastLogoutStr != null) {
      final lastLogout = int.parse(lastLogoutStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastLogout < 300000) { // 5 minutes in milliseconds
        throw const DeviceSwitchException(
          'Please wait 5 minutes before switching devices');
      }
    }
    
    await _registerDevice(currentDevice);
    return true;
  }

  Future<Map<String, dynamic>?> getActiveDevice() async {
    final deviceJson = _prefs.getString(_deviceKey);
    if (deviceJson == null) return null;
    return json.decode(deviceJson);
  }
}

class DeviceSwitchException implements Exception {
  final String message;
  const DeviceSwitchException(this.message);
}