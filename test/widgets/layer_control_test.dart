import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/features/map/presentation/widgets/layer_control.dart';

void main() {
  group('LayerControl Widget Tests', () {
    testWidgets('renders layer checkboxes', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LayerControl(),
            ),
          ),
        ),
      );

      expect(find.text('State Boundaries'), findsOneWidget);
      expect(find.text('Rivers'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('checkboxes are initially checked', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LayerControl(),
            ),
          ),
        ),
      );

      final checkboxes = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
      for (final checkbox in checkboxes) {
        expect(checkbox.value, true);
      }
    });
  });
}