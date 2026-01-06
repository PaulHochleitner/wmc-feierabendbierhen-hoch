import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feierabendbierchen_flutter/widgets/home/stat_card.dart';

void main() {
  group('StatCard Widget Tests', () {
    testWidgets('sollte alle Textelemente korrekt anzeigen', (WidgetTester tester) async {
      // Arrange
      const title = 'Test Titel';
      const value = '100';
      const subtitle = 'Test Untertitel';
      const icon = Icons.local_drink;
      const color = Colors.blue;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: title,
              value: value,
              subtitle: subtitle,
              icon: icon,
              color: color,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(title), findsOneWidget);
      expect(find.text(value), findsOneWidget);
      expect(find.text(subtitle), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
    });

    testWidgets('sollte korrekt strukturiert sein', (WidgetTester tester) async {
      // Arrange
      const statCard = StatCard(
        title: 'Titel',
        value: 'Wert',
        subtitle: 'Untertitel',
        icon: Icons.star,
        color: Colors.red,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: statCard,
          ),
        ),
      );

      // Assert
      // Prüfe dass Container vorhanden ist
      expect(find.byType(Container), findsWidgets);
      // Prüfe dass Row vorhanden ist (für Layout)
      expect(find.byType(Row), findsOneWidget);
      // Prüfe dass Icon vorhanden ist
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
