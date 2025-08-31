import 'package:latlong2/latlong.dart';

enum MapLevel { country, state, district, taluk, poi }

class MapNavigationState {
  final String regionId;
  final String regionName;
  final MapLevel level;
  final LatLng center;
  final double zoom;
  final List<String> breadcrumb;
  final Map<String, dynamic> metadata;

  const MapNavigationState({
    required this.regionId,
    required this.regionName,
    required this.level,
    required this.center,
    required this.zoom,
    this.breadcrumb = const [],
    this.metadata = const {},
  });

  MapNavigationState copyWith({
    String? regionId,
    String? regionName,
    MapLevel? level,
    LatLng? center,
    double? zoom,
    List<String>? breadcrumb,
    Map<String, dynamic>? metadata,
  }) {
    return MapNavigationState(
      regionId: regionId ?? this.regionId,
      regionName: regionName ?? this.regionName,
      level: level ?? this.level,
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      breadcrumb: breadcrumb ?? this.breadcrumb,
      metadata: metadata ?? this.metadata,
    );
  }
}