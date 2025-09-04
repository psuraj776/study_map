import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_logger.dart';
import '../services/secure_device_service.dart';

class OfflineSubscriptionService {
  final AppLogger _logger;
  final SecureDeviceService _deviceService;

  // Updated constructor to match what app_providers.dart expects
  OfflineSubscriptionService(this._logger, this._deviceService);

  /// Activate premium subscription
  Future<bool> activatePremium(String activationCode) async {
    try {
      _logger.info('OfflineSubscriptionService', 'Attempting to activate premium with code: $activationCode');
      
      // TODO: Implement actual premium activation logic
      await Future.delayed(const Duration(seconds: 1));
      
      if (activationCode.isNotEmpty && activationCode.length >= 6) {
        _logger.info('OfflineSubscriptionService', 'Premium activated successfully');
        return true;
      } else {
        _logger.warning('OfflineSubscriptionService', 'Invalid activation code');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.error('OfflineSubscriptionService', 'Error activating premium: $e', stackTrace);
      return false;
    }
  }

  /// Deactivate premium subscription
  Future<void> deactivatePremium() async {
    try {
      _logger.info('OfflineSubscriptionService', 'Deactivating premium subscription');
      
      // TODO: Implement actual premium deactivation logic
      await Future.delayed(const Duration(milliseconds: 500));
      
      _logger.info('OfflineSubscriptionService', 'Premium deactivated successfully');
    } catch (e, stackTrace) {
      _logger.error('OfflineSubscriptionService', 'Error deactivating premium: $e', stackTrace);
      rethrow;
    }
  }

  /// Check premium status
  Future<bool> isPremiumActive() async {
    try {
      final isAuthorized = await _deviceService.isDeviceAuthorized();
      if (!isAuthorized) {
        return false;
      }
      
      // TODO: Implement actual premium status check
      await Future.delayed(const Duration(milliseconds: 200));
      
      // For development, return true
      return true;
    } catch (e, stackTrace) {
      _logger.error('OfflineSubscriptionService', 'Error checking premium status: $e', stackTrace);
      return false;
    }
  }

  /// Get user subscription type
  Future<String> getUserSubscriptionType() async {
    try {
      _logger.debug('OfflineSubscriptionService', 'Getting user subscription type');
      
      // Check if device is authorized first
      final isAuthorized = await _deviceService.isDeviceAuthorized();
      if (!isAuthorized) {
        _logger.warning('OfflineSubscriptionService', 'Device not authorized, returning free subscription');
        return 'free';
      }
      
      // Check premium status
      final isPremium = await isPremiumActive();
      final subscriptionType = isPremium ? 'premium' : 'free';
      
      _logger.info('OfflineSubscriptionService', 'User subscription type: $subscriptionType');
      return subscriptionType;
    } catch (e, stackTrace) {
      _logger.error('OfflineSubscriptionService', 'Error getting subscription type: $e', stackTrace);
      return 'free';
    }
  }

  /// Check if user has premium features
  Future<bool> hasPremiumAccess() async {
    final subscriptionType = await getUserSubscriptionType();
    return subscriptionType == 'premium' || subscriptionType == 'enterprise';
  }

  /// Check if user can access offline data
  Future<bool> canAccessOfflineData() async {
    return await hasPremiumAccess();
  }

  /// Get subscription details
  Future<Map<String, dynamic>> getSubscriptionDetails() async {
    try {
      _logger.debug('OfflineSubscriptionService', 'Getting subscription details');
      
      final subscriptionType = await getUserSubscriptionType();
      final deviceInfo = await _deviceService.getDeviceInfo();
      
      final details = {
        'type': subscriptionType,
        'device': deviceInfo,
        'features': _getFeaturesForSubscription(subscriptionType),
        'expiryDate': subscriptionType == 'free' 
            ? null 
            : DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      };
      
      _logger.debug('OfflineSubscriptionService', 'Subscription details: $details');
      return details;
    } catch (e, stackTrace) {
      _logger.error('OfflineSubscriptionService', 'Error getting subscription details: $e', stackTrace);
      return {
        'type': 'free',
        'features': _getFeaturesForSubscription('free'),
      };
    }
  }

  List<String> _getFeaturesForSubscription(String subscriptionType) {
    switch (subscriptionType) {
      case 'premium':
        return [
          'state_boundaries',
          'district_boundaries',
          'rivers',
          'mountains',
          'offline_data',
        ];
      case 'enterprise':
        return [
          'state_boundaries',
          'district_boundaries',
          'rivers',
          'mountains',
          'roads',
          'railways',
          'offline_data',
          'export_data',
          'api_access',
        ];
      case 'free':
      default:
        return [
          'country_boundaries',
        ];
    }
  }
}