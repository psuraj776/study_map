import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

class OfflineSubscriptionService {
  static const String _subscriptionKey = 'is_premium';
  final SharedPreferences _prefs;
  final AppLogger _logger = AppLogger.instance;

  OfflineSubscriptionService(this._prefs);

  bool isPremiumUser() {
    final isPremium = _prefs.getBool(_subscriptionKey) ?? false;
    _logger.debug('SubscriptionService', 'Premium status check: $isPremium');
    return isPremium;
  }

  Future<void> activatePremium(String activationCode) async {
    _logger.info('SubscriptionService', 'Premium activation attempt with code: $activationCode');
    
    // Simple offline activation code validation
    if (activationCode == 'PREMIUM2025') { // In real app, use more secure validation
      await _prefs.setBool(_subscriptionKey, true);
      _logger.info('SubscriptionService', 'Premium activation successful');
      _logger.authEvent('PREMIUM_ACTIVATION', 'Premium activated successfully');
    } else {
      _logger.warning('SubscriptionService', 'Premium activation failed - invalid code: $activationCode');
      _logger.authEvent('PREMIUM_ACTIVATION_FAILED', 'Invalid activation code');
    }
  }

  Future<void> deactivatePremium() async {
    _logger.info('SubscriptionService', 'Deactivating premium subscription');
    
    await _prefs.setBool(_subscriptionKey, false);
    
    _logger.info('SubscriptionService', 'Premium deactivation completed');
    _logger.authEvent('PREMIUM_DEACTIVATION', 'Premium deactivated');
  }
}