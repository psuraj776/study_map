import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/map_navigation_state.dart';
import '../controllers/map_navigation_controller.dart';
import '../../features/map/domain/repositories/map_repository.dart';
import '../../services/app_logger.dart';
import '../../services/secure_device_service.dart';
import '../../services/offline_subscription_service.dart';

// Logger Provider
final loggerProvider = Provider<AppLogger>((ref) {
  return AppLogger();
});

// Device Service Provider
final deviceServiceProvider = Provider<SecureDeviceService>((ref) {
  final logger = ref.read(loggerProvider);
  return SecureDeviceService(logger);
});

// Device Authentication State Provider
final deviceAuthStateProvider = FutureProvider<bool>((ref) async {
  final deviceService = ref.read(deviceServiceProvider);
  return await deviceService.isDeviceAuthorized();
});

// Subscription Service Provider
final subscriptionServiceProvider = Provider<OfflineSubscriptionService>((ref) {
  final logger = ref.read(loggerProvider);
  final deviceService = ref.read(deviceServiceProvider);
  return OfflineSubscriptionService(logger, deviceService);
});

// User Subscription State Provider
final userSubscriptionProvider = FutureProvider<String>((ref) async {
  final subscriptionService = ref.read(subscriptionServiceProvider);
  return await subscriptionService.getUserSubscriptionType();
});

// Map Repository Provider
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final logger = ref.read(loggerProvider);
  return MapRepository(logger);
});

// Map Navigation Provider
final mapNavigationProvider = StateNotifierProvider<MapNavigationController, MapNavigationState>((ref) {
  final logger = ref.read(loggerProvider);
  final repository = ref.read(mapRepositoryProvider);
  return MapNavigationController(logger, repository);
});

// Current Level Polygons Provider (for navigation)
final currentLevelPolygonsProvider = FutureProvider<List<Polygon>>((ref) async {
  final navigation = ref.watch(mapNavigationProvider);
  final repository = ref.read(mapRepositoryProvider);
  final logger = ref.read(loggerProvider);

  try {
    logger.debug('CurrentLevelPolygonsProvider', 'Loading polygons for level: ${navigation.level}, region: ${navigation.regionId}');

    switch (navigation.level) {
      case MapLevel.state:
        if (navigation.regionId.isNotEmpty) {
          return await repository.loadDistrictPolygons(navigation.regionId);
        }
        break;
      case MapLevel.district:
        if (navigation.regionId.isNotEmpty) {
          return await repository.loadTalukPolygons(navigation.regionId);
        }
        break;
      case MapLevel.country:
      case MapLevel.taluk:
      case MapLevel.poi:
      default:
        return [];
    }

    return [];
  } catch (e, stackTrace) {
    logger.error('CurrentLevelPolygonsProvider', 'Error loading polygons: $e', stackTrace);
    return [];
  }
});

// POI Provider (for points of interest)
final currentPOIsProvider = FutureProvider<List<Marker>>((ref) async {
  final navigation = ref.watch(mapNavigationProvider);
  final repository = ref.read(mapRepositoryProvider);
  final logger = ref.read(loggerProvider);

  try {
    logger.debug('CurrentPOIsProvider', 'Loading POIs for level: ${navigation.level}, region: ${navigation.regionId}');

    if (navigation.regionId.isNotEmpty) {
      final pois = await repository.loadPOIsForRegion(
        navigation.regionId, 
        navigation.level.toString().split('.').last,
      );
      
      logger.info('CurrentPOIsProvider', 'Loaded ${pois.length} POIs');
      return pois;
    }

    return [];
  } catch (e, stackTrace) {
    logger.error('CurrentPOIsProvider', 'Error loading POIs: $e', stackTrace);
    return [];
  }
});