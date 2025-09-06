import 'package:flutter/material.dart';
import '../constants/dev_config.dart';
import '../../l10n/app_localizations.dart';

class LayerInfo {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final bool isEnabled;
  final bool isPremium;
  final List<LayerInfo> subLayers;

  const LayerInfo({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    this.isEnabled = false,
    this.isPremium = false,
    this.subLayers = const [],
  });

  // Get localized name
  String getName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (nameKey) {
      case 'indiaBoundaries':
        return l10n.indiaBoundaries;
      case 'stateBoundaries':
        return l10n.stateBoundaries;
      case 'geography':
        return l10n.geography;
      case 'rivers':
        return l10n.rivers;
      case 'mountains':
        return l10n.mountains;
      case 'infrastructure':
        return l10n.infrastructure;
      case 'roads':
        return l10n.roads;
      case 'railways':
        return l10n.railways;
      default:
        return nameKey;
    }
  }

  // Get localized description
  String getDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (descriptionKey) {
      case 'countryOutline':
        return 'Shows country outline';
      case 'stateBoundariesDesc':
        return 'Shows state boundaries and allows navigation';
      case 'geographicFeatures':
        return 'Geographic features like rivers, mountains';
      case 'majorRivers':
        return 'Major rivers and water bodies';
      case 'mountainRanges':
        return 'Mountain ranges and peaks';
      case 'infrastructureDesc':
        return 'Roads, railways, airports';
      case 'majorHighways':
        return 'Major highways and roads';
      case 'railwayNetworks':
        return 'Railway networks';
      default:
        return descriptionKey;
    }
  }

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
    String? nameKey,
    String? descriptionKey,
    bool? isEnabled,
    bool? isPremium,
    List<LayerInfo>? subLayers,
  }) {
    return LayerInfo(
      id: id ?? this.id,
      nameKey: nameKey ?? this.nameKey,
      descriptionKey: descriptionKey ?? this.descriptionKey,
      isEnabled: isEnabled ?? this.isEnabled,
      isPremium: isPremium ?? this.isPremium,
      subLayers: subLayers ?? this.subLayers,
    );
  }
}

// Updated layer definitions with description keys
class AppLayers {
  static const LayerInfo india = LayerInfo(
    id: 'india',
    nameKey: 'indiaBoundaries',
    descriptionKey: 'countryOutline',
    isEnabled: true,
    isPremium: false,
  );

  static const LayerInfo states = LayerInfo(
    id: 'states',
    nameKey: 'stateBoundaries',
    descriptionKey: 'stateBoundariesDesc',
    isEnabled: false,
    isPremium: true,
  );

  static const LayerInfo geography = LayerInfo(
    id: 'geography',
    nameKey: 'geography',
    descriptionKey: 'geographicFeatures',
    isEnabled: false,
    isPremium: true,
    subLayers: [
      LayerInfo(
        id: 'geography_rivers',
        nameKey: 'rivers',
        descriptionKey: 'majorRivers',
        isEnabled: false,
        isPremium: true,
      ),
      LayerInfo(
        id: 'geography_mountains',
        nameKey: 'mountains',
        descriptionKey: 'mountainRanges',
        isEnabled: false,
        isPremium: true,
      ),
    ],
  );

  static const LayerInfo infrastructure = LayerInfo(
    id: 'infrastructure',
    nameKey: 'infrastructure',
    descriptionKey: 'infrastructureDesc',
    isEnabled: false,
    isPremium: true,
    subLayers: [
      LayerInfo(
        id: 'infrastructure_roads',
        nameKey: 'roads',
        descriptionKey: 'majorHighways',
        isEnabled: false,
        isPremium: true,
      ),
      LayerInfo(
        id: 'infrastructure_railways',
        nameKey: 'railways',
        descriptionKey: 'railwayNetworks',
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