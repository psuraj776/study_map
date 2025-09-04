import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/layer_models.dart';
import '../constants/dev_config.dart';

// Layer menu visibility provider
class LayerMenuVisibilityNotifier extends StateNotifier<bool> {
  LayerMenuVisibilityNotifier() : super(false);

  void toggle() {
    state = !state;
  }

  void show() {
    state = true;
  }

  void hide() {
    state = false;
  }
}

final layerMenuVisibilityProvider = StateNotifierProvider<LayerMenuVisibilityNotifier, bool>(
  (ref) => LayerMenuVisibilityNotifier(),
);

// Layer states provider
class LayerStatesNotifier extends StateNotifier<Map<String, bool>> {
  LayerStatesNotifier() : super({
    'india': true,  // Always enabled
    'states': DevConfig.isPremiumUser, // Auto-enable in dev mode
    'geography': false,
    'geography_rivers': false,
    'geography_mountains': false,
    'infrastructure': false,
    'infrastructure_roads': false,
    'infrastructure_railways': false,
  });

  void toggleLayer(String layerId) {
    final layer = _findLayerById(layerId);
    
    if (layer == null) return;
    
    // Check accessibility (includes dev mode checks)
    if (!layer.isAccessible) {
      // In dev mode, show a different message
      if (DevConfig.isDevelopmentMode) {
        print('DEV: Layer $layerId is premium but dev overrides disabled');
      }
      return;
    }

    state = {
      ...state,
      layerId: !(state[layerId] ?? false),
    };
  }

  bool isLayerEffectivelyEnabled(String layerId) {
    final layer = _findLayerById(layerId);
    if (layer == null) return false;
    
    // Check if layer is accessible (dev mode aware)
    if (!layer.isAccessible) return false;
    
    return state[layerId] ?? false;
  }

  // Development helper - force enable all premium features
  void enableAllPremiumForDev() {
    if (!DevConfig.isDevelopmentMode) return;
    
    final newState = <String, bool>{};
    for (final layer in AppLayers.allLayers) {
      newState[layer.id] = true;
      for (final subLayer in layer.subLayers) {
        newState[subLayer.id] = true;
      }
    }
    state = newState;
  }

  // Development helper - simulate free user
  void simulateFreeUser() {
    if (!DevConfig.isDevelopmentMode) return;
    
    state = {
      'india': true,  // Only free features
      'states': false,
      'geography': false,
      'geography_rivers': false,
      'geography_mountains': false,
      'infrastructure': false,
      'infrastructure_roads': false,
      'infrastructure_railways': false,
    };
  }

  LayerInfo? _findLayerById(String layerId) {
    for (final layer in AppLayers.allLayers) {
      if (layer.id == layerId) return layer;
      for (final subLayer in layer.subLayers) {
        if (subLayer.id == layerId) return subLayer;
      }
    }
    return null;
  }
}

final layerStatesProvider = StateNotifierProvider<LayerStatesNotifier, Map<String, bool>>(
  (ref) => LayerStatesNotifier(),
);