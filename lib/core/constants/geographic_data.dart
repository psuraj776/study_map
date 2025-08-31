import 'package:latlong2/latlong.dart';

class GeographicData {
  // Only essential state metadata in app bundle
  static const Map<String, StateInfo> states = {
    'rajasthan': StateInfo(
      id: 'rajasthan',
      name: 'Rajasthan',
      center: LatLng(27.0238, 74.2179),
      bounds: {'minLat': 23.0, 'maxLat': 30.2, 'minLng': 69.4, 'maxLng': 78.3},
      hasOfflineData: true,
      districts: ['jhalawar', 'jaipur', 'jodhpur', 'udaipur', 'kota', 'ajmer'],
    ),
    'gujarat': StateInfo(
      id: 'gujarat',
      name: 'Gujarat',
      center: LatLng(22.2587, 71.1924),
      bounds: {'minLat': 20.1, 'maxLat': 24.7, 'minLng': 68.1, 'maxLng': 74.4},
      hasOfflineData: false,
      districts: [],
    ),
    'maharashtra': StateInfo(
      id: 'maharashtra',
      name: 'Maharashtra',
      center: LatLng(19.7515, 75.7139),
      bounds: {'minLat': 15.6, 'maxLat': 22.0, 'minLng': 72.6, 'maxLng': 80.9},
      hasOfflineData: false,
      districts: [],
    ),
    // Add more states as needed...
  };
  
  static const Map<String, DistrictInfo> districts = {
    'rajasthan_jhalawar': DistrictInfo(
      id: 'rajasthan_jhalawar',
      name: 'Jhalawar',
      stateId: 'rajasthan',
      center: LatLng(24.5965, 76.1637),
      bounds: {'minLat': 24.0, 'maxLat': 25.2, 'minLng': 75.8, 'maxLng': 76.8},
      hasOfflineData: true,
    ),
    // Add more districts as needed...
  };
  
  // Get all states that have offline data available
  static List<StateInfo> get statesWithOfflineData {
    return states.values.where((state) => state.hasOfflineData).toList();
  }
  
  // Get all districts for a state
  static List<DistrictInfo> getDistrictsForState(String stateId) {
    return districts.values.where((district) => district.stateId == stateId).toList();
  }
}

class StateInfo {
  final String id;
  final String name;
  final LatLng center;
  final Map<String, double> bounds;
  final bool hasOfflineData;
  final List<String> districts;
  
  const StateInfo({
    required this.id,
    required this.name,
    required this.center,
    required this.bounds,
    required this.hasOfflineData,
    required this.districts,
  });
}

class DistrictInfo {
  final String id;
  final String name;
  final String stateId;
  final LatLng center;
  final Map<String, double> bounds;
  final bool hasOfflineData;
  
  const DistrictInfo({
    required this.id,
    required this.name,
    required this.stateId,
    required this.center,
    required this.bounds,
    required this.hasOfflineData,
  });
}