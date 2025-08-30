import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/features/map/domain/models/layer_model.dart';

void main() {
  group('MapLayer Model Tests', () {
    test('creates MapLayer with required fields', () {
      final layer = MapLayer(
        id: 'states',
        name: 'State Boundaries',
        path: 'assets/layers/states.geojson',
        type: LayerType.polygon,
        tier: LayerTier.free,
        color: Colors.blue,
      );

      expect(layer.id, 'states');
      expect(layer.name, 'State Boundaries');
      expect(layer.visible, false); // default value
      expect(layer.type, LayerType.polygon);
      expect(layer.tier, LayerTier.free);
    });

    test('copyWith updates visibility', () {
      final layer = MapLayer(
        id: 'states',
        name: 'State Boundaries',
        path: 'assets/layers/states.geojson',
        type: LayerType.polygon,
        tier: LayerTier.free,
        color: Colors.blue,
        visible: false,
      );

      final updatedLayer = layer.copyWith(visible: true);

      expect(updatedLayer.visible, true);
      expect(updatedLayer.id, layer.id); // other fields unchanged
      expect(updatedLayer.name, layer.name);
    });

    test('LayerType enum has correct values', () {
      expect(LayerType.values, [LayerType.polygon, LayerType.polyline]);
    });

    test('LayerTier enum has correct values', () {
      expect(LayerTier.values, [LayerTier.free, LayerTier.premium]);
    });
  });
}