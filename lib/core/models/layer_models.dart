import '../constants/dev_config.dart';

class LayerInfo {
  final String id;
  final String name;
  final String description;
  final bool isEnabled;
  final bool isPremium;
  final List<LayerInfo> subLayers;

  const LayerInfo({
    required this.id,
    required this.name,
    required this.description,
    this.isEnabled = false,
    this.isPremium = false,
    this.subLayers = const [],
  });

  // Development helper - checks if layer should be accessible
  bool get isAccessible {
    if (DevConfig.isDevelopmentMode) {
      // In dev mode, check for specific overrides
      if (DevConfig.premiumFeatureOverrides.containsKey(id)) {
        return DevConfig.premiumFeatureOverrides[id]!;
      }
      // Default to accessible in dev mode
      return true;
    }
    
    // In production, check actual premium status
    return !isPremium || _isUserPremium();
  }

  // Development helper - shows premium status with dev info
  String get accessibilityStatus {
    if (DevConfig.isDevelopmentMode) {
      if (isPremium && DevConfig.simulatePremiumUser) {
        return 'DEV: Premium (Simulated)';
      } else if (isPremium && !DevConfig.simulatePremiumUser) {
        return 'DEV: Premium (Blocked)';
      } else {
        return 'DEV: Free';
      }
    }
    
    return isPremium ? 'Premium' : 'Free';
  }

  bool _isUserPremium() {
    // In development, use the simulated user type
    if (DevConfig.isDevelopmentMode) {
      return DevConfig.isPremiumUser;
    }
    
    // TODO: Replace with actual user subscription check
    return false;
  }

  LayerInfo copyWith({
    String? id,
    String? name,
    String? description,
    bool? isEnabled,
    bool? isPremium,
    List<LayerInfo>? subLayers,
  }) {
    return LayerInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      isPremium: isPremium ?? this.isPremium,
      subLayers: subLayers ?? this.subLayers,
    );
  }
}

// Updated layer definitions with premium flags
class AppLayers {
  static const LayerInfo india = LayerInfo(
    id: 'india',
    name: 'India Boundaries',
    description: 'Shows country outline',
    isEnabled: true,
    isPremium: false, // Free feature
  );

  static const LayerInfo states = LayerInfo(
    id: 'states',
    name: 'State Boundaries',
    description: 'Shows state boundaries and allows navigation',
    isEnabled: false,
    isPremium: true, // Premium feature
  );

  static const LayerInfo geography = LayerInfo(
    id: 'geography',
    name: 'Geography',
    description: 'Geographic features like rivers, mountains',
    isEnabled: false,
    isPremium: true, // Premium feature
    subLayers: [
      LayerInfo(
        id: 'geography_rivers',
        name: 'Rivers',
        description: 'Major rivers and water bodies',
        isEnabled: false,
        isPremium: true,
      ),
      LayerInfo(
        id: 'geography_mountains',
        name: 'Mountains',
        description: 'Mountain ranges and peaks',
        isEnabled: false,
        isPremium: true,
      ),
    ],
  );

  static const LayerInfo infrastructure = LayerInfo(
    id: 'infrastructure',
    name: 'Infrastructure',
    description: 'Roads, railways, airports',
    isEnabled: false,
    isPremium: true, // Premium feature
    subLayers: [
      LayerInfo(
        id: 'infrastructure_roads',
        name: 'Roads',
        description: 'Major highways and roads',
        isEnabled: false,
        isPremium: true,
      ),
      LayerInfo(
        id: 'infrastructure_railways',
        name: 'Railways',
        description: 'Railway networks',
        isEnabled: false,
        isPremium: true,
      ),
    ],
  );

  static List<LayerInfo> get allLayers => [
    india,
    states,
    geography,
    infrastructure,
  ];
}