import 'package:latlong2/latlong.dart';

enum MapLevel {
  country,
  state,
  district,
  taluk,
  poi, // This was missing from the switch case
}

class MapNavigationState {
  final MapLevel level;
  final String regionId;
  final String regionName;
  final LatLng center;
  final double zoom;
  final List<String> breadcrumb;

  const MapNavigationState({
    required this.level,
    required this.regionId,
    required this.regionName,
    required this.center,
    required this.zoom,
    required this.breadcrumb,
  });

  // Add the missing initial constructor
  const MapNavigationState.initial()
      : level = MapLevel.country,
        regionId = '',
        regionName = 'India',
        center = const LatLng(20.5937, 78.9629),
        zoom = 5.0,
        breadcrumb = const ['India'];

  MapNavigationState copyWith({
    MapLevel? level,
    String? regionId,
    String? regionName,
    LatLng? center,
    double? zoom,
    List<String>? breadcrumb,
  }) {
    return MapNavigationState(
      level: level ?? this.level,
      regionId: regionId ?? this.regionId,
      regionName: regionName ?? this.regionName,
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      breadcrumb: breadcrumb ?? this.breadcrumb,
    );
  }

  @override
  String toString() {
    return 'MapNavigationState(level: $level, regionId: $regionId, regionName: $regionName, center: $center, zoom: $zoom, breadcrumb: $breadcrumb)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapNavigationState &&
        other.level == level &&
        other.regionId == regionId &&
        other.regionName == regionName &&
        other.center == center &&
        other.zoom == zoom &&
        other.breadcrumb.length == breadcrumb.length &&
        _listEquals(other.breadcrumb, breadcrumb);
  }

  @override
  int get hashCode {
    return level.hashCode ^
        regionId.hashCode ^
        regionName.hashCode ^
        center.hashCode ^
        zoom.hashCode ^
        breadcrumb.hashCode;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}