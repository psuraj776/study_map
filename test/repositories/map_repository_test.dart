import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../lib/features/map/domain/repositories/map_repository.dart';

void main() {
  group('MapRepository Tests', () {
    late MapRepository repository;

    setUp(() {
      repository = MapRepository();
    });

    testWidgets('loadStatePolygons returns empty list on asset error', (tester) async {
      // Arrange - Mock asset bundle to throw error
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (call) async {
          if (call.method == 'loadString') {
            throw PlatformException(code: 'AssetNotFound');
          }
          return null;
        },
      );

      // Act
      final result = await repository.loadStatePolygons();

      // Assert
      expect(result, isEmpty);
    });

    testWidgets('loadStatePolygons parses valid GeoJSON', (tester) async {
      // Arrange - Mock valid GeoJSON
      const validGeoJson = '''
      {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "Polygon",
              "coordinates": [[[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]]
            },
            "properties": {}
          }
        ]
      }
      ''';

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (call) async {
          if (call.method == 'loadString') {
            return validGeoJson;
          }
          return null;
        },
      );

      // Act
      final result = await repository.loadStatePolygons();

      // Assert
      expect(result, isA<List<Polygon>>());
      expect(result.length, greaterThan(0));
    });
  });
}