import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import '../../../lib/core/models/map_navigation_state.dart';

void main() {
  group('MapNavigationState Tests', () {
    test('creates MapNavigationState with required fields', () {
      const state = MapNavigationState(
        regionId: 'india',
        regionName: 'India',
        level: MapLevel.country,
        center: LatLng(20.5937, 78.9629),
        zoom: 4.0,
        breadcrumb: ['India'],
      );

      expect(state.regionId, 'india');
      expect(state.regionName, 'India');
      expect(state.level, MapLevel.country);
      expect(state.center, const LatLng(20.5937, 78.9629));
      expect(state.zoom, 4.0);
      expect(state.breadcrumb, ['India']);
      expect(state.metadata, isEmpty);
    });

    test('copyWith updates specific fields', () {
      const originalState = MapNavigationState(
        regionId: 'india',
        regionName: 'India',
        level: MapLevel.country,
        center: LatLng(20.5937, 78.9629),
        zoom: 4.0,
        breadcrumb: ['India'],
      );

      final updatedState = originalState.copyWith(
        regionId: 'karnataka',
        regionName: 'Karnataka',
        level: MapLevel.state,
        zoom: 6.0,
        breadcrumb: ['India', 'Karnataka'],
      );

      expect(updatedState.regionId, 'karnataka');
      expect(updatedState.regionName, 'Karnataka');
      expect(updatedState.level, MapLevel.state);
      expect(updatedState.zoom, 6.0);
      expect(updatedState.breadcrumb, ['India', 'Karnataka']);
      // Unchanged fields
      expect(updatedState.center, originalState.center);
    });

    test('MapLevel enum has correct values', () {
      expect(MapLevel.values, [
        MapLevel.country,
        MapLevel.state,
        MapLevel.district,
        MapLevel.taluk,
        MapLevel.poi,
      ]);
    });
  });
}