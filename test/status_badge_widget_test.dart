import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspection/view/global_widgets/status_badge_widget.dart';

void main() {
  group('StatusBadgeWidget Tests', () {
    testWidgets('renders outlined badge with transparent background, colored border, and dot', (tester) async {
      const testColor = Colors.purple;
      const testText = 'Inspection Assigned';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadgeWidget(
              statusText: testText,
              statusColor: testColor,
            ),
          ),
        ),
      );

      // Verify text
      expect(find.text(testText), findsOneWidget);

      // Verify text style color
      final textWidget = tester.widget<Text>(find.text(testText));
      expect(textWidget.style?.color, equals(testColor));

      // Verify badge container decoration (transparent background, rounded pill radius, thin border)
      final badgeContainerFinder = find.byType(Container).first;
      final badgeContainer = tester.widget<Container>(badgeContainerFinder);
      final decoration = badgeContainer.decoration as BoxDecoration;

      expect(decoration.color, equals(testColor.withOpacity(0.12)));
      expect(decoration.borderRadius, equals(BorderRadius.circular(20)));
      expect(decoration.border?.top.color, equals(testColor));
      expect(decoration.border?.top.width, equals(1.0));

      // Verify status dot is rendered
      final dotContainerFinder = find.descendant(
        of: badgeContainerFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(dotContainerFinder, findsOneWidget);

      final dotContainer = tester.widget<Container>(dotContainerFinder);
      final dotDecoration = dotContainer.decoration as BoxDecoration;
      expect(dotDecoration.color, equals(testColor));
      expect(dotContainer.constraints?.maxWidth, equals(7));
      expect(dotContainer.constraints?.maxHeight, equals(7));
    });

    testWidgets('renders outlined badge without dot when showDot is false', (tester) async {
      const testColor = Colors.blue;
      const testText = 'Re-Inspection in Progress';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadgeWidget(
              statusText: testText,
              statusColor: testColor,
              showDot: false,
              fontSize: 8,
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);

      // Verify no circular dot container exists
      final dotContainerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      expect(dotContainerFinder, findsNothing);
    });

    testWidgets('renders multiple status variants correctly', (tester) async {
      final statuses = [
        {'text': 'Jobcard Open', 'color': Colors.blue},
        {'text': 'Pending', 'color': Colors.orange},
        {'text': 'Completed', 'color': Colors.green},
        {'text': 'Re-Inspection Rejected', 'color': Colors.red},
      ];

      for (final item in statuses) {
        final text = item['text'] as String;
        final color = item['color'] as Color;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusBadgeWidget(
                statusText: text,
                statusColor: color,
              ),
            ),
          ),
        );

        expect(find.text(text), findsOneWidget);
        final textWidget = tester.widget<Text>(find.text(text));
        expect(textWidget.style?.color, equals(color));
      }
    });
  });
}
