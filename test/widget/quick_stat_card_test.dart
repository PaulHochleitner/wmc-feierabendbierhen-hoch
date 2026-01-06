import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feierabendbierchen_flutter/widgets/home/quick_stat_card.dart';

void main() {
  group('QuickStatCard Widget Tests', () {
    testWidgets('sollte alle Textelemente korrekt anzeigen', (WidgetTester tester) async {
      // Arrange
      const title = 'Gesamt';
      const value = '42';
      const icon = Icons.local_drink;
      const color = Colors.green;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickStatCard(
              title: title,
              value: value,
              icon: icon,
              color: color,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(title), findsOneWidget);
      expect(find.text(value), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
    });

    testWidgets('sollte korrekt strukturiert sein', (WidgetTester tester) async {
      // Arrange
      const quickStatCard = QuickStatCard(
        title: 'Titel',
        value: '100',
        icon: Icons.bar_chart,
        color: Colors.blue,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: quickStatCard,
          ),
        ),
      );

      // Assert
      // Prüfe dass Container vorhanden ist
      expect(find.byType(Container), findsWidgets);
      // Prüfe dass Column vorhanden ist (für vertikales Layout)
      expect(find.byType(Column), findsOneWidget);
      // Prüfe dass Icon vorhanden ist
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    testWidgets('sollte verschiedene Werte korrekt anzeigen', (WidgetTester tester) async {
      // Arrange
      const testCases = [
        {'title': 'Gesamt', 'value': '0'},
        {'title': 'Diese Woche', 'value': '5'},
        {'title': 'Durchschnitt', 'value': '2.5'},
      ];

      for (final testCase in testCases) {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuickStatCard(
                title: testCase['title']!,
                value: testCase['value']!,
                icon: Icons.local_drink,
                color: Colors.blue,
              ),
            ),
          ),
        );

        // Assert
        expect(find.text(testCase['title']!), findsOneWidget);
        expect(find.text(testCase['value']!), findsOneWidget);
      }
    });
  });
}
