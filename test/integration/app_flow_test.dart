import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/main.dart';
import '../../lib/core/providers/app_providers.dart';

void main() {
  group('App Flow Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('app shows login screen for new user', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceAuthStateProvider.overrideWith((ref) => Future.value(false)),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Device Authorization'), findsOneWidget);
      expect(find.text('Device Not Authorized'), findsOneWidget);
    });

    testWidgets('app shows map screen for authorized device', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceAuthStateProvider.overrideWith((ref) => Future.value(true)),
            statePolygonsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('India Map'), findsOneWidget);
    });

    testWidgets('navigation between login and map works', (tester) async {
      bool isAuthorized = false;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceAuthStateProvider.overrideWith((ref) => Future.value(isAuthorized)),
            statePolygonsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();
      // Initially shows login screen
      expect(find.text('Device Authorization'), findsOneWidget);

      // Simulate authorization by rebuilding with new value
      isAuthorized = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceAuthStateProvider.overrideWith((ref) => Future.value(isAuthorized)),
            statePolygonsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();
      // Now shows map screen
      expect(find.text('India Map'), findsOneWidget);
    });

    testWidgets('app shows loading state initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceAuthStateProvider.overrideWith((ref) => Future.delayed(
              const Duration(milliseconds: 100),
              () => true,
            )),
          ],
          child: const MyApp(),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for future to complete
      await tester.pumpAndSettle();
      
      // Should now show the map screen
      expect(find.text('India Map'), findsOneWidget);
    });

    testWidgets('app handles auth error gracefully', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceAuthStateProvider.overrideWith((ref) => Future.error('Auth failed')),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Error loading auth state'), findsOneWidget);
    });
  });
}