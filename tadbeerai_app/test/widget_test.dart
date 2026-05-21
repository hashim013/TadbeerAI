// Basic Flutter widget tests for TadbeerAI shared widgets.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeerai/core/models/tadbeer_models.dart';
import 'package:tadbeerai/shared/widgets/shared_widgets.dart';

void main() {
  group('Shared Widgets Tests', () {
    testWidgets('TBadge displays label and icon correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TBadge(
              label: 'Test Badge',
              color: Colors.red,
              bg: Colors.redAccent,
              icon: Icons.check,
            ),
          ),
        ),
      );

      // Verify label is present
      expect(find.text('Test Badge'), findsOneWidget);

      // Verify icon is present
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('TUrgencyDot renders with correct shape', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TUrgencyDot(
              urgency: UrgencyLevel.high,
              size: 12.0,
            ),
          ),
        ),
      );

      // Find the container widget representing the dot
      final dotFinder = find.byType(TUrgencyDot);
      expect(dotFinder, findsOneWidget);

      final Container container = tester.widget<Container>(
        find.descendant(
          of: dotFinder,
          matching: find.byType(Container),
        ),
      );

      // Verify size and shape
      final boxDecoration = container.decoration as BoxDecoration;
      expect(boxDecoration.shape, BoxShape.circle);
      expect(container.constraints?.minWidth, 12.0);
      expect(container.constraints?.minHeight, 12.0);
    });
  });
}
