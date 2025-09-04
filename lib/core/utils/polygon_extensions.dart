import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

extension PolygonExtensions on Polygon {
  /// Creates a new Polygon with modified properties
  Polygon copyWith({
    List<LatLng>? points,
    Color? color,
    Color? borderColor,
    double? borderStrokeWidth,
    String? label,
  }) {
    return Polygon(
      points: points ?? this.points,
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderStrokeWidth: borderStrokeWidth ?? this.borderStrokeWidth,
      label: label ?? this.label,
    );
  }
}