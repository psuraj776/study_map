import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/map_navigation_state.dart';
import '../../features/map/domain/repositories/map_repository.dart';
import '../../services/app_logger.dart';

class MapNavigationController extends StateNotifier<MapNavigationState> {
  final AppLogger _logger;
  final MapRepository _mapRepository;

  MapNavigationController(this._logger, this._mapRepository)
      : super(const MapNavigationState.initial());

  /// Navigate to a specific state
  void navigateToState(String stateId, String stateName, LatLng center) async {
    final previousState = state;
    
    // Log navigation event
    _logger.navigationEvent('NAVIGATE_TO_STATE', {
      'from': '${previousState.regionName} (${previousState.level.name})',
      'to': '$stateName (state)',
      'stateId': stateId,
      'stateName': stateName,
      'center': {'lat': center.latitude, 'lng': center.longitude},
    });

    // Calculate zoom level for state view
    double zoom = 7.0;

    // Update navigation state
    state = MapNavigationState(
      level: MapLevel.state,
      regionId: stateId,
      regionName: stateName,
      center: center,
      zoom: zoom,
      breadcrumb: [...state.breadcrumb, stateName],
    );

    _logger.info('MapNavigationController', 'Navigated to state: $stateName');
  }

  /// Navigate to a specific district
  void navigateToDistrict(String districtId, String districtName, LatLng center) async {
    final previousState = state;
    
    // Log navigation event
    _logger.navigationEvent('NAVIGATE_TO_DISTRICT', {
      'from': '${previousState.regionName} (${previousState.level.name})',
      'to': '$districtName (district)',
      'districtId': districtId,
      'districtName': districtName,
      'center': {'lat': center.latitude, 'lng': center.longitude},
    });

    // Calculate zoom level for district view
    double zoom = 9.0;

    // Update navigation state
    state = MapNavigationState(
      level: MapLevel.district,
      regionId: districtId,
      regionName: districtName,
      center: center,
      zoom: zoom,
      breadcrumb: [...state.breadcrumb, districtName],
    );

    _logger.info('MapNavigationController', 'Navigated to district: $districtName');
  }

  /// Navigate to a specific taluk
  void navigateToTaluk(String talukId, String talukName, LatLng center) async {
    final previousState = state;

    // Log navigation event
    _logger.navigationEvent('NAVIGATE_TO_TALUK', {
      'from': '${previousState.regionName} (${previousState.level.name})',
      'to': '$talukName (taluk)',
      'talukId': talukId,
      'talukName': talukName,
      'center': {'lat': center.latitude, 'lng': center.longitude},
    });

    // Calculate zoom level for taluk view
    double zoom = 11.0;

    // Update navigation state
    state = MapNavigationState(
      level: MapLevel.taluk,
      regionId: talukId,
      regionName: talukName,
      center: center,
      zoom: zoom,
      breadcrumb: [...state.breadcrumb, talukName],
    );

    _logger.info('MapNavigationController', 'Navigated to taluk: $talukName');
  }

  /// Go back to the previous level
  void goBack() {
    final previousState = state;
    
    if (state.breadcrumb.length <= 1) {
      _logger.warning('MapNavigationController', 'Cannot go back from country level');
      return;
    }

    // Determine parent level and region
    final newBreadcrumb = state.breadcrumb.sublist(0, state.breadcrumb.length - 1);
    final MapLevel parentLevel;
    final String parentRegionId;
    final String parentRegionName = newBreadcrumb.last;

    switch (state.level) {
      case MapLevel.state:
        parentLevel = MapLevel.country;
        parentRegionId = '';
        break;
      case MapLevel.district:
        parentLevel = MapLevel.state;
        parentRegionId = _getStateIdFromBreadcrumb(newBreadcrumb);
        break;
      case MapLevel.taluk:
        parentLevel = MapLevel.district;
        parentRegionId = _getDistrictIdFromBreadcrumb(newBreadcrumb);
        break;
      case MapLevel.poi:
        parentLevel = MapLevel.taluk;
        parentRegionId = _getTalukIdFromBreadcrumb(newBreadcrumb);
        break;
      case MapLevel.country:
      default:
        _logger.warning('MapNavigationController', 'Cannot go back from ${state.level}');
        return;
    }

    // Log navigation event
    _logger.navigationEvent('GO_BACK', {
      'from': '${previousState.regionName} (${previousState.level.name})',
      'to': '$parentRegionName (${parentLevel.name})',
      'parentLevel': parentLevel.name,
      'parentRegionId': parentRegionId,
    });

    // Calculate appropriate center and zoom for parent level
    final LatLng parentCenter = _getCenterForLevel(parentLevel, parentRegionId);
    final double parentZoom = _getZoomForLevel(parentLevel);

    // Update navigation state
    state = MapNavigationState(
      level: parentLevel,
      regionId: parentRegionId,
      regionName: parentRegionName,
      center: parentCenter,
      zoom: parentZoom,
      breadcrumb: newBreadcrumb,
    );

    _logger.info('MapNavigationController', 'Navigated back to: $parentRegionName');
  }

  /// Navigate to home (country level)
  void navigateHome() {
    final previousState = state;
    
    // Log navigation event
    _logger.navigationEvent('NAVIGATE_HOME', {
      'from': '${previousState.regionName} (${previousState.level.name})',
      'to': 'India (country)',
      'action': 'home',
    });

    state = const MapNavigationState.initial();
    _logger.info('MapNavigationController', 'Navigated to home (country level)');
  }

  /// Update map center and zoom (for manual map movements)
  void updateMapView(LatLng center, double zoom) {
    state = state.copyWith(center: center, zoom: zoom);
    _logger.debug('MapNavigationController', 'Updated map view: center=$center, zoom=$zoom');
  }

  // Helper methods
  String _getStateIdFromBreadcrumb(List<String> breadcrumb) {
    // TODO: Implement logic to get state ID from breadcrumb
    return '';
  }

  String _getDistrictIdFromBreadcrumb(List<String> breadcrumb) {
    // TODO: Implement logic to get district ID from breadcrumb
    return '';
  }

  String _getTalukIdFromBreadcrumb(List<String> breadcrumb) {
    // TODO: Implement logic to get taluk ID from breadcrumb
    return '';
  }

  LatLng _getCenterForLevel(MapLevel level, String regionId) {
    switch (level) {
      case MapLevel.country:
        return const LatLng(20.5937, 78.9629); // India center
      case MapLevel.state:
        // TODO: Get state center from geographic data
        return const LatLng(20.5937, 78.9629);
      case MapLevel.district:
        // TODO: Get district center from geographic data
        return const LatLng(20.5937, 78.9629);
      case MapLevel.taluk:
        // TODO: Get taluk center from geographic data
        return const LatLng(20.5937, 78.9629);
      case MapLevel.poi:
        // TODO: Get POI center from geographic data
        return const LatLng(20.5937, 78.9629);
    }
  }

  double _getZoomForLevel(MapLevel level) {
    switch (level) {
      case MapLevel.country:
        return 5.0;
      case MapLevel.state:
        return 7.0;
      case MapLevel.district:
        return 9.0;
      case MapLevel.taluk:
        return 11.0;
      case MapLevel.poi:
        return 13.0;
    }
  }
}