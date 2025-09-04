import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/map/presentation/screens/map_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: OfflineMapApp(),
    ),
  );
}

class OfflineMapApp extends StatelessWidget {
  const OfflineMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Map App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
