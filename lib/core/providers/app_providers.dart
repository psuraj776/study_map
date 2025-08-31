import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../services/secure_device_service.dart';
import '../../services/offline_subscription_service.dart';
import '../../features/map/domain/repositories/map_repository.dart';
import '../controllers/map_navigation_controller.dart';
import '../models/map_navigation_state.dart';

// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

// Device Auth Providers
final deviceServiceProvider = Provider<SecureDeviceService>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SecureDeviceService(prefs);
  } catch (e) {
    print('Error creating device service: $e');
    rethrow;
  }
});

final deviceAuthStateProvider = FutureProvider<bool>((ref) async {
  try {
    print('Checking device auth state...');
    final deviceService = ref.watch(deviceServiceProvider);
    final result = await deviceService.validateDevice();
    print('Device auth result: $result');
    return result;
  } catch (e) {
    print('Error in deviceAuthStateProvider: $e');
    rethrow;
  }
});

// Subscription Service Provider
final subscriptionServiceProvider = Provider<OfflineSubscriptionService>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return OfflineSubscriptionService(prefs);
  } catch (e) {
    print('Error creating subscription service: $e');
    rethrow;
  }
});

final premiumStatusProvider = Provider<bool>((ref) {
  try {
    final subscriptionService = ref.watch(subscriptionServiceProvider);
    return subscriptionService.isPremiumUser();
  } catch (e) {
    print('Error checking premium status: $e');
    return false; // Default to false on error
  }
});

// Navigation Provider
final mapNavigationProvider = StateNotifierProvider<MapNavigationController, MapNavigationState>((ref) {
  return MapNavigationController();
});

// Map Repository Provider
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository();
});

// Dynamic Layer Providers based on current map level
final currentLevelPolygonsProvider = FutureProvider<List<Polygon>>((ref) async {
  try {
    final repository = ref.watch(mapRepositoryProvider);
    final navigation = ref.watch(mapNavigationProvider);
    
    print('Loading polygons for level: ${navigation.level}, region: ${navigation.regionId}');
    
    switch (navigation.level) {
      case MapLevel.country:
        return repository.loadStatePolygons();
      case MapLevel.state:
        return repository.loadDistrictPolygons(navigation.regionId);
      case MapLevel.district:
        return repository.loadTalukPolygons(navigation.regionId);
      case MapLevel.taluk:
      case MapLevel.poi:
        return [];
    }
  } catch (e) {
    print('Error loading polygons: $e');
    return [];
  }
});

// Keep the state polygons provider for backward compatibility
final statePolygonsProvider = FutureProvider<List<Polygon>>((ref) async {
  try {
    final repository = ref.watch(mapRepositoryProvider);
    return repository.loadStatePolygons();
  } catch (e) {
    print('Error loading state polygons: $e');
    return [];
  }
});

// POI provider for future use
final currentLevelPOIsProvider = FutureProvider<List<Marker>>((ref) async {
  final repository = ref.watch(mapRepositoryProvider);
  final navigation = ref.watch(mapNavigationProvider);
  
  // Only load POIs for district level and below
  if (navigation.level == MapLevel.district || 
      navigation.level == MapLevel.taluk || 
      navigation.level == MapLevel.poi) {
    return repository.loadPOIsForRegion(
      navigation.regionId, 
      navigation.level.toString().split('.').last, // Gets 'district', 'taluk', etc.
    );
  }
  
  return [];
});