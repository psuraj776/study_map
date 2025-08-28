import 'package:flutter/material.dart';

enum LayerType { polygon, polyline }
enum LayerTier { free, premium }

class MapLayer {
  final String id;
  final String name;
  final String path;
  final LayerType type;
  final LayerTier tier;
  final bool visible;
  final Color color;

  const MapLayer({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.tier,
    required this.color,
    this.visible = false,
  });

  MapLayer copyWith({bool? visible}) {
    return MapLayer(
      id: id,
      name: name,
      path: path,
      type: type,
      tier: tier,
      color: color,
      visible: visible ?? this.visible,
    );
  }
}