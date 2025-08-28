import 'package:shared_preferences.dart';

class OfflineSubscriptionService {
  static const String _subscriptionKey = 'is_premium';
  final SharedPreferences _prefs;

  OfflineSubscriptionService(this._prefs);

  bool isPremiumUser() {
    return _prefs.getBool(_subscriptionKey) ?? false;
  }

  Future<void> activatePremium(String activationCode) async {
    // Simple offline activation code validation
    if (activationCode == 'PREMIUM2025') { // In real app, use more secure validation
      await _prefs.setBool(_subscriptionKey, true);
    }
  }
}