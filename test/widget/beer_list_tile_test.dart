import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feierabendbierchen_flutter/widgets/beer/beer_list_tile.dart';
import 'package:feierabendbierchen_flutter/models/consumed_beer.dart';

void main() {
  group('BeerListTile Widget Tests', () {
    final testBeer = ConsumedBeer(
      id: 'test-id',
      name: 'Gösser Export',
      country: '🇦🇹 Österreich',
      percentage: 5.0,
      rating: 8,
      date: DateTime(2024, 1, 15),
      latitude: 48.2082,
      longitude: 16.3738,
      locationName: 'Wien',
    );

    testWidgets('sollte alle Bier-Informationen korrekt anzeigen',
        (WidgetTester tester) async {
      // Arrange
      final animationController = AnimationController(
        vsync: tester,
        duration: const Duration(seconds: 1),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BeerListTile(
              beer: testBeer,
              animation: animationController,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Gösser Export'), findsOneWidget);
      expect(find.text('5.0%'), findsOneWidget);
      // Rating wird als " 8/10" angezeigt (mit Leerzeichen)
      expect(find.textContaining('8/10'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('sollte Edit-Button korrekt funktionieren',
        (WidgetTester tester) async {
      // Arrange
      bool editCalled = false;
      final animationController = AnimationController(
        vsync: tester,
        duration: const Duration(seconds: 1),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BeerListTile(
              beer: testBeer,
              animation: animationController,
              onEdit: () => editCalled = true,
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Assert
      expect(editCalled, isTrue);
    });

    testWidgets('sollte Delete-Button korrekt funktionieren',
        (WidgetTester tester) async {
      // Arrange
      bool deleteCalled = false;
      final animationController = AnimationController(
        vsync: tester,
        duration: const Duration(seconds: 1),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BeerListTile(
              beer: testBeer,
              animation: animationController,
              onEdit: () {},
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Assert
      expect(deleteCalled, isTrue);
    });
  });
}
