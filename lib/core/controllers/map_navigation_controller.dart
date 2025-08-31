import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/map_navigation_state.dart';
import '../constants/map_constants.dart';

class MapNavigationController extends StateNotifier<MapNavigationState> {
  MapNavigationController() : super(
    const MapNavigationState(
      regionId: 'india',
      regionName: 'India',
      level: MapLevel.country,
      center: MapConstants.indiaCenter,
      zoom: MapConstants.defaultZoom,
      breadcrumb: ['India'],
    ),
  );

  void navigateToState(String stateId, String stateName, LatLng center) {
    final newBreadcrumb = [...state.breadcrumb, stateName];
    
    state = state.copyWith(
      regionId: stateId,
      regionName: stateName,
      level: MapLevel.state,
      center: center,
      zoom: 6.0,
      breadcrumb: newBreadcrumb,
    );
  }

  void navigateToDistrict(String districtId, String districtName, LatLng center) {
    final newBreadcrumb = [...state.breadcrumb, districtName];
    
    state = state.copyWith(
      regionId: districtId,
      regionName: districtName,
      level: MapLevel.district,
      center: center,
      zoom: 8.0,
      breadcrumb: newBreadcrumb,
    );
  }

  void goBack() {
    if (state.breadcrumb.length <= 1) return;

    final newBreadcrumb = state.breadcrumb.sublist(0, state.breadcrumb.length - 1);
    final parentLevel = _getParentLevel(state.level);
    
    state = state.copyWith(
      level: parentLevel,
      breadcrumb: newBreadcrumb,
      zoom: _getZoomForLevel(parentLevel),
    );
  }

  void navigateHome() {
    state = const MapNavigationState(
      regionId: 'india',
      regionName: 'India',
      level: MapLevel.country,
      center: MapConstants.indiaCenter,
      zoom: MapConstants.defaultZoom,
      breadcrumb: ['India'],
    );
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
        return 6.0;
      case MapLevel.district:
        return 8.0;
      case MapLevel.taluk:
        return 10.0;
      case MapLevel.poi:
        return 12.0;
    }
  }
}