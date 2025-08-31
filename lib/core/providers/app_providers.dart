import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../services/secure_device_service.dart';
import '../../services/offline_subscription_service.dart';
import '../../services/app_logger.dart'; // Add this import
import '../../features/map/domain/repositories/map_repository.dart';
import '../controllers/map_navigation_controller.dart';
import '../models/map_navigation_state.dart';

// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

// Logger Provider
final loggerProvider = Provider<AppLogger>((ref) {
  return AppLogger.instance;
});

// Device Auth Providers
final deviceServiceProvider = Provider<SecureDeviceService>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SecureDeviceService(prefs);
  } catch (e) {
    final logger = ref.read(loggerProvider);
    logger.error('DeviceService', 'Error creating device service', e);
    rethrow;
  }
});

final deviceAuthStateProvider = FutureProvider<bool>((ref) async {
  final logger = ref.read(loggerProvider);
  try {
    logger.debug('Auth', 'Checking device auth state...');
    final deviceService = ref.watch(deviceServiceProvider);
    final result = await deviceService.validateDevice();
    logger.authEvent('VALIDATION_RESULT', 'Device valid: $result');
    return result;
  } catch (e, stackTrace) {
    logger.error('Auth', 'Error in deviceAuthStateProvider', e, stackTrace);
    rethrow;
  }
});

// Subscription Service Provider
final subscriptionServiceProvider = Provider<OfflineSubscriptionService>((ref) {
  final logger = ref.read(loggerProvider);
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return OfflineSubscriptionService(prefs);
  } catch (e) {
    logger.error('Subscription', 'Error creating subscription service', e);
    rethrow;
  }
});

final premiumStatusProvider = Provider<bool>((ref) {
  final logger = ref.read(loggerProvider);
  try {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    final isPremium = subscriptionService.isPremiumUser();
    logger.debug('Subscription', 'Premium status: $isPremium');
    return isPremium;
  } catch (e) {
    logger.error('Subscription', 'Error checking premium status', e);
    return false;
  }
});

// Navigation Provider
final mapNavigationProvider = StateNotifierProvider<MapNavigationController, MapNavigationState>((ref) {
  final logger = ref.read(loggerProvider);
  final mapRepository = ref.read(mapRepositoryProvider); // Add this line
  return MapNavigationController(logger, mapRepository); // Pass both parameters
});

// Map Repository Provider
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final logger = ref.read(loggerProvider);
  return MapRepository(logger);
});

// Layer Visibility Providers
final stateLayerVisibilityProvider = StateProvider<bool>((ref) => false);
final riverLayerVisibilityProvider = StateProvider<bool>((ref) => false);

// Dynamic Layer Providers based on current map level and visibility
final currentLevelPolygonsProvider = FutureProvider<List<Polygon>>((ref) async {
  final logger = ref.read(loggerProvider);
  final stopwatch = Stopwatch()..start();
  
  try {
    final repository = ref.watch(mapRepositoryProvider);
    final navigation = ref.watch(mapNavigationProvider);
    final isStateLayerVisible = ref.watch(stateLayerVisibilityProvider);
    
    logger.debug('Polygons', 'Loading polygons for level: ${navigation.level}, region: ${navigation.regionId}');
    logger.layerEvent('LAYER_VISIBILITY_CHECK', 'States', isStateLayerVisible);
    
    switch (navigation.level) {
      case MapLevel.country:
        if (isStateLayerVisible) {
          final polygons = await repository.loadStatePolygons();
          logger.performance('LOAD_STATE_POLYGONS', stopwatch.elapsedMilliseconds, {
            'count': polygons.length,
            'level': 'country'
          });
          return polygons;
        } else {
          logger.debug('Polygons', 'State layer is hidden');
          return [];
        }
      case MapLevel.state:
        final polygons = await repository.loadDistrictPolygons(navigation.regionId);
        logger.performance('LOAD_DISTRICT_POLYGONS', stopwatch.elapsedMilliseconds, {
          'count': polygons.length,
          'stateId': navigation.regionId
        });
        return polygons;
      case MapLevel.district:
        final polygons = await repository.loadTalukPolygons(navigation.regionId);
        logger.performance('LOAD_TALUK_POLYGONS', stopwatch.elapsedMilliseconds, {
          'count': polygons.length,
          'districtId': navigation.regionId
        });
        return polygons;
      case MapLevel.taluk:
      case MapLevel.poi:
        return [];
    }
  } catch (e, stackTrace) {
    logger.error('Polygons', 'Error loading polygons', e, stackTrace);
    return [];
  } finally {
    stopwatch.stop();
  }
});

// Keep the state polygons provider for backward compatibility
final statePolygonsProvider = FutureProvider<List<Polygon>>((ref) async {
  final logger = ref.read(loggerProvider);
  try {
    final repository = ref.watch(mapRepositoryProvider);
    final isVisible = ref.watch(stateLayerVisibilityProvider);
    
    if (!isVisible) return [];
    
    return repository.loadStatePolygons();
  } catch (e, stackTrace) {
    logger.error('Polygons', 'Error loading state polygons', e, stackTrace);
    return [];
  }
});
/*
// River lines provider (when you have data)
final riverLinesProvider = FutureProvider<List<Polyline>>((ref) async {
  try {
    final repository = ref.watch(mapRepositoryProvider);
    final isVisible = ref.watch(riverLayerVisibilityProvider);
    final isPremium = ref.watch(premiumStatusProvider);
    
    if (!isVisible || !isPremium) return [];
    
    return repository.loadRiverLines();
  } catch (e) {
    print('Error loading river lines: $e');
    return [];
  }
});
*/
// POI provider for future use
final currentLevelPOIsProvider = FutureProvider<List<Marker>>((ref) async {
  final logger = ref.read(loggerProvider);
  final repository = ref.watch(mapRepositoryProvider);
  final navigation = ref.watch(mapNavigationProvider);
  
  // Only load POIs for district level and below
  if (navigation.level == MapLevel.district || 
      navigation.level == MapLevel.taluk || 
      navigation.level == MapLevel.poi) {
    try {
      final pois = await repository.loadPOIsForRegion(
        navigation.regionId, 
        navigation.level.toString().split('.').last,
      );
      logger.debug('POI', 'Loaded ${pois.length} POIs for ${navigation.regionId}');
      return pois;
    } catch (e, stackTrace) {
      logger.error('POI', 'Error loading POIs', e, stackTrace);
      return [];
    }
  }
  
  return [];
});