class DevConfig {
  // Set this to true during development to bypass premium restrictions
  static const bool isDevelopmentMode = true;
  
  // Override premium features for development
  static const bool enableAllPremiumFeatures = true;
  
  // Debug flags
  static const bool showDebugInfo = true;
  static const bool enableDetailedLogging = true;
  
  // Premium feature overrides (for development)
  static const Map<String, bool> premiumFeatureOverrides = {
    'states_layer': true,
    'districts_layer': true,
    'taluks_layer': true,
    'rivers_layer': true,
    'geography_layers': true,
    'offline_data': true,
    'detailed_maps': true,
    'export_features': true,
  };
  
  // Development user simulation
  static const bool simulatePremiumUser = true;
  static const String devUserType = 'premium'; // 'free', 'premium', 'enterprise'
  
  // Quick toggle for testing different user states
  static bool get isPremiumUser => simulatePremiumUser || isDevelopmentMode;
  static bool get isFreeUser => !isPremiumUser && !isDevelopmentMode;
}