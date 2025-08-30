import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../services/secure_device_service.dart';
import '../../features/map/domain/repositories/map_repository.dart';

// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Device Auth Providers
final deviceServiceProvider = Provider<SecureDeviceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SecureDeviceService(prefs);
});

final deviceAuthStateProvider = FutureProvider<bool>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return await deviceService.validateDevice();
});

// Map Repository Provider
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository();
});

// Layer Providers
final statePolygonsProvider = FutureProvider<List<Polygon>>((ref) async {
  final repository = ref.watch(mapRepositoryProvider);
  return repository.loadStatePolygons();
});
/*
final riverLinesProvider = FutureProvider<List<Polyline>>((ref) async {
  final repository = ref.watch(mapRepositoryProvider);
  return repository.loadRiverLines();
});
*/