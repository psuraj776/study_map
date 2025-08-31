import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math; // Add this line
import '../models/map_navigation_state.dart';
import '../constants/map_constants.dart';
import '../../services/app_logger.dart';
import '../../features/map/domain/repositories/map_repository.dart';

class MapNavigationController extends StateNotifier<MapNavigationState> {
  final AppLogger logger;
  final MapRepository mapRepository; // Add this

  MapNavigationController(this.logger, this.mapRepository) : super( // Update constructor
    const MapNavigationState(
      regionId: 'india',
      regionName: 'India',
      level: MapLevel.country,
      center: MapConstants.indiaCenter,
      zoom: MapConstants.defaultZoom,
      breadcrumb: ['India'],
    ),
  ) {
    logger.debug('Navigation', 'MapNavigationController initialized');
  }

  void navigateToState(String stateId, String stateName, LatLng center) async {
    final previousState = state;
    final newBreadcrumb = [...state.breadcrumb, stateName];
    
    // Try to get actual bounds for the state
    final bounds = await mapRepository.getStateBounds(stateId);
    
    LatLng stateCenter;
    double stateZoom;
    
    if (bounds != null) {
      // Calculate center from bounds
      stateCenter = LatLng(
        (bounds['minLat']! + bounds['maxLat']!) / 2,
        (bounds['minLng']! + bounds['maxLng']!) / 2,
      );
      
      // Calculate zoom to fit bounds (with some padding)
      final latDiff = bounds['maxLat']! - bounds['minLat']!;
      final lngDiff = bounds['maxLng']! - bounds['minLng']!;
      final maxDiff = math.max(latDiff, lngDiff);
      
      // Zoom calculation: larger area = lower zoom
      if (maxDiff > 8) {
        stateZoom = 5.0;
      } else if (maxDiff > 5) {
        stateZoom = 6.0;
      } else if (maxDiff > 3) {
        stateZoom = 6.5;
      } else if (maxDiff > 2) {
        stateZoom = 7.0;
      } else if (maxDiff > 1) {
        stateZoom = 7.5;
      } else {
        stateZoom = 8.0;
      }
      
      logger.debug('Navigation', 'Calculated bounds for $stateId: center=$stateCenter, zoom=$stateZoom, bounds=$bounds');
    } else {
      // Fallback to predefined values
      stateCenter = _getStateCenter(stateId, center);
      stateZoom = _getStateZoom(stateId);
      logger.debug('Navigation', 'Using fallback center/zoom for $stateId');
    }
    
    state = state.copyWith(
      regionId: stateId,
      regionName: stateName,
      level: MapLevel.state,
      center: stateCenter,
      zoom: stateZoom,
      breadcrumb: newBreadcrumb,
    );

    logger.navigationEvent(
      '${previousState.regionName} (${previousState.level.name})',
      '$stateName (state)',
      'state'
    );
    
    logger.mapEvent('NAVIGATE_TO_STATE', {
      'stateId': stateId,
      'stateName': stateName,
      'center': {'lat': stateCenter.latitude, 'lng': stateCenter.longitude},
      'zoom': stateZoom,
      'breadcrumb': newBreadcrumb,
      'usedBounds': bounds != null,
    });
  }

  void navigateToDistrict(String districtId, String districtName, LatLng center) async {
    final previousState = state;
    final newBreadcrumb = [...state.breadcrumb, districtName];
    
    // Try to get actual bounds for the district
    final bounds = await mapRepository.getDistrictBounds(districtId);
    
    LatLng districtCenter;
    double districtZoom;
    
    if (bounds != null) {
      // Calculate center from bounds
      districtCenter = LatLng(
        (bounds['minLat']! + bounds['maxLat']!) / 2,
        (bounds['minLng']! + bounds['maxLng']!) / 2,
      );
      
      // Calculate zoom to fit bounds (with some padding)
      final latDiff = bounds['maxLat']! - bounds['minLat']!;
      final lngDiff = bounds['maxLng']! - bounds['minLng']!;
      final maxDiff = math.max(latDiff, lngDiff);
      
      // Zoom calculation for districts: smaller area = higher zoom
      if (maxDiff > 3) {
        districtZoom = 7.0;
      } else if (maxDiff > 2) {
        districtZoom = 7.5;
      } else if (maxDiff > 1.5) {
        districtZoom = 8.0;
      } else if (maxDiff > 1) {
        districtZoom = 8.5;
      } else if (maxDiff > 0.5) {
        districtZoom = 9.0;
      } else {
        districtZoom = 9.5;
      }
      
      logger.debug('Navigation', 'Calculated bounds for $districtId: center=$districtCenter, zoom=$districtZoom, bounds=$bounds');
    } else {
      // Fallback to predefined values
      districtCenter = _getDistrictCenter(districtId, center);
      districtZoom = _getDistrictZoom(districtId);
      logger.debug('Navigation', 'Using fallback center/zoom for $districtId');
    }
    
    state = state.copyWith(
      regionId: districtId,
      regionName: districtName,
      level: MapLevel.district,
      center: districtCenter,
      zoom: districtZoom,
      breadcrumb: newBreadcrumb,
    );

    logger.navigationEvent(
      '${previousState.regionName} (${previousState.level.name})',
      '$districtName (district)',
      'district'
    );
    
    logger.mapEvent('NAVIGATE_TO_DISTRICT', {
      'districtId': districtId,
      'districtName': districtName,
      'center': {'lat': districtCenter.latitude, 'lng': districtCenter.longitude},
      'zoom': districtZoom,
      'breadcrumb': newBreadcrumb,
      'usedBounds': bounds != null,
    });
  }

  void goBack() {
    if (state.breadcrumb.length <= 1) {
      logger.debug('Navigation', 'Cannot go back - already at root level');
      return;
    }

    final previousState = state;
    final newBreadcrumb = state.breadcrumb.sublist(0, state.breadcrumb.length - 1);
    final parentLevel = _getParentLevel(state.level);
    
    // Get appropriate center and zoom for parent level
    LatLng parentCenter;
    double parentZoom;
    String parentRegionId;
    String parentRegionName;
    
    if (parentLevel == MapLevel.country) {
      parentCenter = MapConstants.indiaCenter;
      parentZoom = MapConstants.defaultZoom;
      parentRegionId = 'india';
      parentRegionName = 'India';
    } else {
      // For state level, we need to extract state info from breadcrumb
      parentRegionName = newBreadcrumb.last;
      parentRegionId = parentRegionName; // This should work for most cases
      parentCenter = _getStateCenter(parentRegionId, state.center);
      parentZoom = _getZoomForLevel(parentLevel);
    }
    
    state = state.copyWith(
      regionId: parentRegionId,
      regionName: parentRegionName,
      level: parentLevel,
      center: parentCenter,
      zoom: parentZoom,
      breadcrumb: newBreadcrumb,
    );

    logger.navigationEvent(
      '${previousState.regionName} (${previousState.level.name})',
      '${newBreadcrumb.last} (${parentLevel.name})',
      'back'
    );
  }

  void navigateHome() {
    final previousState = state;
    
    state = const MapNavigationState(
      regionId: 'india',
      regionName: 'India',
      level: MapLevel.country,
      center: MapConstants.indiaCenter,
      zoom: MapConstants.defaultZoom,
      breadcrumb: ['India'],
    );

    logger.navigationEvent(
      '${previousState.regionName} (${previousState.level.name})',
      'India (country)',
      'home'
    );
  }

  // Get state-specific center coordinates
  LatLng _getStateCenter(String stateId, LatLng fallbackCenter) {
    final stateCenters = <String, LatLng>{
      'Rajasthan': const LatLng(27.0238, 74.2179),
      'Gujarat': const LatLng(22.2587, 71.1924),
      'Maharashtra': const LatLng(19.7515, 75.7139),
      'Karnataka': const LatLng(15.3173, 75.7139),
      'Tamil Nadu': const LatLng(11.1271, 78.6569),
      'Uttar Pradesh': const LatLng(26.8467, 80.9462),
      'Madhya Pradesh': const LatLng(22.9734, 78.6569),
      'West Bengal': const LatLng(22.9868, 87.8550),
      'Odisha': const LatLng(20.9517, 85.0985),
      'Andhra Pradesh': const LatLng(15.9129, 79.7400),
      'Telangana': const LatLng(18.1124, 79.0193),
      'Kerala': const LatLng(10.8505, 76.2711),
      'Punjab': const LatLng(31.1471, 75.3412),
      'Haryana': const LatLng(29.0588, 76.0856),
      'Bihar': const LatLng(25.0961, 85.3131),
      'Jharkhand': const LatLng(23.6102, 85.2799),
      'Assam': const LatLng(26.2006, 92.9376),
      'Himachal Pradesh': const LatLng(31.1048, 77.1734),
      'Uttarakhand': const LatLng(30.0668, 79.0193),
      'Chhattisgarh': const LatLng(21.2787, 81.8661),
      'Goa': const LatLng(15.2993, 74.1240),
      'Arunachal Pradesh': const LatLng(28.2180, 94.7278),
      'Manipur': const LatLng(24.6637, 93.9063),
      'Meghalaya': const LatLng(25.4670, 91.3662),
      'Mizoram': const LatLng(23.1645, 92.9376),
      'Nagaland': const LatLng(26.1584, 94.5624),
      'Sikkim': const LatLng(27.5330, 88.5122),
      'Tripura': const LatLng(23.9408, 91.9882),
    };
    
    return stateCenters[stateId] ?? fallbackCenter;
  }

  // Get district-specific center coordinates
  LatLng _getDistrictCenter(String districtId, LatLng fallbackCenter) {
    final districtCenters = <String, LatLng>{
      // Rajasthan districts
      'rajasthan_jhalawar': const LatLng(24.5965, 76.1637),
      'rajasthan_jodhpur': const LatLng(26.2389, 73.0243),
      'rajasthan_jaipur': const LatLng(26.9124, 75.7873),
      'rajasthan_udaipur': const LatLng(24.5854, 73.7125),
      'rajasthan_kota': const LatLng(25.2138, 75.8648),
      'rajasthan_ajmer': const LatLng(26.4499, 74.6399),
      'rajasthan_alwar': const LatLng(27.5530, 76.6346),
      'rajasthan_bikaner': const LatLng(28.0229, 73.3119),
      'rajasthan_bharatpur': const LatLng(27.2173, 77.4890),
      'rajasthan_jaisalmer': const LatLng(26.9157, 70.9083),
      // Add more districts as needed
    };
    
    return districtCenters[districtId.toLowerCase()] ?? fallbackCenter;
  }

  // Get state-specific zoom levels
  double _getStateZoom(String stateId) {
    final stateZooms = <String, double>{
      'Rajasthan': 6.5, // Large state, moderate zoom
      'Gujarat': 6.8,
      'Maharashtra': 6.5,
      'Karnataka': 6.8,
      'Tamil Nadu': 7.0,
      'Uttar Pradesh': 6.2, // Very large state
      'Madhya Pradesh': 6.3,
      'West Bengal': 7.2,
      'Odisha': 7.0,
      'Andhra Pradesh': 7.0,
      'Telangana': 7.5,
      'Kerala': 7.5, // Small state, higher zoom
      'Punjab': 7.5,
      'Haryana': 8.0, // Small state
      'Bihar': 7.2,
      'Jharkhand': 7.5,
      'Assam': 7.0,
      'Himachal Pradesh': 7.0,
      'Uttarakhand': 7.2,
      'Chhattisgarh': 7.0,
      'Goa': 9.0, // Very small state, high zoom
      'Arunachal Pradesh': 6.5,
      'Manipur': 8.5,
      'Meghalaya': 8.5,
      'Mizoram': 8.5,
      'Nagaland': 8.0,
      'Sikkim': 9.5,
      'Tripura': 8.5,
    };
    
    return stateZooms[stateId] ?? 6.5; // Default zoom for states
  }

  // Get district-specific zoom levels
  double _getDistrictZoom(String districtId) {
    final districtZooms = <String, double>{
      // Rajasthan districts
      'rajasthan_jhalawar': 8.5,
      'rajasthan_jodhpur': 8.0, // Large district
      'rajasthan_jaipur': 8.5,
      'rajasthan_udaipur': 8.2,
      'rajasthan_kota': 9.0,
      'rajasthan_ajmer': 8.8,
      'rajasthan_alwar': 8.3,
      'rajasthan_bikaner': 7.8, // Large district
      'rajasthan_bharatpur': 9.2,
      'rajasthan_jaisalmer': 7.5, // Very large district
      // Add more districts as needed
    };
    
    return districtZooms[districtId.toLowerCase()] ?? 8.5; // Default zoom for districts
  }

  MapLevel _getParentLevel(MapLevel currentLevel) {
    switch (currentLevel) {
      case MapLevel.poi:
        return MapLevel.taluk;
      case MapLevel.taluk:
        return MapLevel.district;
      case MapLevel.district:
        return MapLevel.state;
      case MapLevel.state:
        return MapLevel.country;
      case MapLevel.country:
        return MapLevel.country;
    }
  }

  double _getZoomForLevel(MapLevel level) {
    switch (level) {
      case MapLevel.country:
        return 4.0;
      case MapLevel.state:
        return 6.5;
      case MapLevel.district:
        return 8.5;
      case MapLevel.taluk:
        return 10.0;
      case MapLevel.poi:
        return 12.0;
    }
  }
}