import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geojson_vi/geojson_vi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  List<Polygon> polygons = [];
  List<Polyline> polylines = [];

  @override
  void initState() {
    super.initState();
    loadGeoJson();
  }

  Future<void> loadGeoJson() async {
    final String geojsonStr =
        await rootBundle.loadString('assets/mapdata.geojson');
    final geojson = GeoJSONFeatureCollection.fromJSON(jsonDecode(geojsonStr));

    final newPolys = <Polygon>[];
    final newLines = <Polyline>[];

    for (final feature in geojson.features) {
      // ✅ Safely handle nullable feature/geometry
      final geom = (feature as GeoJSONFeature?)?.geometry;
      if (geom == null) continue;

      if (geom is GeoJSONPolygon) {
        if (geom.coordinates.isEmpty) continue;
        final coords =
            geom.coordinates[0].map((c) => LatLng(c[1], c[0])).toList();
        newPolys.add(
          Polygon(
            points: coords,
            borderColor: Colors.blue,
            // ✅ Fix deprecation: use withValues instead of withOpacity
            color: Colors.blue.withValues(alpha: 0.3),
            borderStrokeWidth: 2,
          ),
        );
      } else if (geom is GeoJSONLineString) {
        if (geom.coordinates.isEmpty) continue;
        final coords =
            geom.coordinates.map((c) => LatLng(c[1], c[0])).toList();
        newLines.add(
          Polyline(points: coords, strokeWidth: 3, color: Colors.green),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      polygons = newPolys;
      polylines = newLines;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GeoJSON Map")),
      body: FlutterMap(
        options: const MapOptions(
          // flutter_map v8 API
          initialCenter: LatLng(20.5937, 78.9629),
          initialZoom: 4,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),
          PolygonLayer(polygons: polygons),
          PolylineLayer(polylines: polylines),
        ],
      ),
    );
  }
}
