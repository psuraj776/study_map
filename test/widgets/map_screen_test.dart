import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../lib/features/map/presentation/screens/map_screen.dart';
import '../../lib/core/providers/app_providers.dart';

void main() {
  group('MapScreen Widget Tests', () {
    testWidgets('renders app bar with title and layers button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statePolygonsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(home: MapScreen()),
        ),
      );

      expect(find.text('India Map'), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('renders map widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statePolygonsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(home: MapScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('shows layer control bottom sheet when layers button is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statePolygonsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(home: MapScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap layers button
      await tester.tap(find.byIcon(Icons.layers));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears
      expect(find.text('State Boundaries'), findsOneWidget);
      expect(find.text('Rivers'), findsOneWidget);
    });
  });
}