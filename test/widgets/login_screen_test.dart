import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/features/auth/presentation/screens/login_screen.dart';
import '../../lib/core/providers/app_providers.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('shows loading indicator when auth state is loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceAuthStateProvider.overrideWith((ref) => Future.delayed(
              const Duration(seconds: 1),
              () => true,
            )),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows authorized state when device is valid', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceAuthStateProvider.overrideWith((ref) => Future.value(true)),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Device Authorized'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('shows unauthorized state when device is invalid', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceAuthStateProvider.overrideWith((ref) => Future.value(false)),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Device Not Authorized'), findsOneWidget);
      expect(find.byIcon(Icons.no_accounts), findsOneWidget);
      expect(find.text('Authorize This Device'), findsOneWidget);
    });

    testWidgets('shows error state when auth fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceAuthStateProvider.overrideWith((ref) => Future.error('Auth failed')),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Error: Auth failed'), findsOneWidget);
    });
  });
}