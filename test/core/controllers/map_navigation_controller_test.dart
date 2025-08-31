import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../lib/core/controllers/map_navigation_controller.dart';
import '../../../lib/core/models/map_navigation_state.dart';

void main() {
  group('MapNavigationController Tests', () {
    late ProviderContainer container;
    late MapNavigationController controller;

    setUp(() {
      container = ProviderContainer();
      controller = MapNavigationController();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is country level India', () {
      expect(controller.state.regionId, 'india');
      expect(controller.state.regionName, 'India');
      expect(controller.state.level, MapLevel.country);
      expect(controller.state.breadcrumb, ['India']);
    });

    test('navigateToState updates state correctly', () {
      const testCenter = LatLng(15.3173, 75.7139);
      
      controller.navigateToState('karnataka', 'Karnataka', testCenter);

      expect(controller.state.regionId, 'karnataka');
      expect(controller.state.regionName, 'Karnataka');
      expect(controller.state.level, MapLevel.state);
      expect(controller.state.center, testCenter);
      expect(controller.state.zoom, 6.0);
      expect(controller.state.breadcrumb, ['India', 'Karnataka']);
    });

    test('navigateToDistrict updates state correctly', () {
      const testCenter = LatLng(12.9716, 77.5946);
      
      // First navigate to state
      controller.navigateToState('karnataka', 'Karnataka', const LatLng(15.3173, 75.7139));
      
      // Then navigate to district
      controller.navigateToDistrict('bangalore', 'Bangalore Urban', testCenter);

      expect(controller.state.regionId, 'bangalore');
      expect(controller.state.regionName, 'Bangalore Urban');
      expect(controller.state.level, MapLevel.district);
      expect(controller.state.center, testCenter);
      expect(controller.state.zoom, 8.0);
      expect(controller.state.breadcrumb, ['India', 'Karnataka', 'Bangalore Urban']);
    });

    test('goBack navigates to parent level', () {
      // Navigate to district level
      controller.navigateToState('karnataka', 'Karnataka', const LatLng(15.3173, 75.7139));
      controller.navigateToDistrict('bangalore', 'Bangalore Urban', const LatLng(12.9716, 77.5946));
      
      // Go back
      controller.goBack();

      expect(controller.state.level, MapLevel.state);
      expect(controller.state.breadcrumb, ['India', 'Karnataka']);
    });

    test('goBack from country level does nothing', () {
      controller.goBack();

      expect(controller.state.level, MapLevel.country);
      expect(controller.state.breadcrumb, ['India']);
    });

    test('navigateHome resets to initial state', () {
      // Navigate somewhere
      controller.navigateToState('karnataka', 'Karnataka', const LatLng(15.3173, 75.7139));
      
      // Navigate home
      controller.navigateHome();

      expect(controller.state.regionId, 'india');
      expect(controller.state.regionName, 'India');
      expect(controller.state.level, MapLevel.country);
      expect(controller.state.breadcrumb, ['India']);
    });
  });
}