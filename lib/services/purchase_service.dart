import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences.dart';

class PurchaseService {
  static const String _premiumKey = 'is_premium_user';
  static const String _subscriptionId = 'premium_features_yearly';
  
  final InAppPurchase _iap = InAppPurchase.instance;
  final SharedPreferences _prefs;

  PurchaseService(this._prefs);

  Future<bool> isPremiumUser() async {
    return _prefs.getBool(_premiumKey) ?? false;
  }

  Future<void> initializePurchases() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    const Set<String> _kIds = {_subscriptionId};
    final ProductDetailsResponse response = 
        await _iap.queryProductDetails(_kIds);

    if (response.notFoundIDs.isNotEmpty) {
      throw Exception('Some products not found: ${response.notFoundIDs}');
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Stream<List<PurchaseDetails>> get purchaseUpdates => 
      _iap.purchaseStream;

  void handlePurchaseUpdate(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      await _prefs.setBool(_premiumKey, true);
    }
  }
}