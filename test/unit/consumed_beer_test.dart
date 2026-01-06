import 'package:flutter_test/flutter_test.dart';
import 'package:feierabendbierchen_flutter/models/consumed_beer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('ConsumedBeer', () {
    final testDate = DateTime(2024, 1, 15, 18, 30);

    test('sollte ConsumedBeer korrekt erstellen', () {
      // Arrange & Act
      final beer = ConsumedBeer(
        id: 'test-id',
        name: 'Test Bier',
        country: '🇦🇹 Österreich',
        percentage: 5.0,
        rating: 8,
        date: testDate,
        latitude: 48.2082,
        longitude: 16.3738,
        locationName: 'Wien',
      );

      // Assert
      expect(beer.id, equals('test-id'));
      expect(beer.name, equals('Test Bier'));
      expect(beer.country, equals('🇦🇹 Österreich'));
      expect(beer.percentage, equals(5.0));
      expect(beer.rating, equals(8));
      expect(beer.date, equals(testDate));
      expect(beer.latitude, equals(48.2082));
      expect(beer.longitude, equals(16.3738));
      expect(beer.locationName, equals('Wien'));
    });

    test('sollte toFirestore korrekt konvertieren', () {
      // Arrange
      final beer = ConsumedBeer(
        name: 'Test Bier',
        country: '🇦🇹 Österreich',
        percentage: 5.0,
        rating: 8,
        date: testDate,
        latitude: 48.2082,
        longitude: 16.3738,
        locationName: 'Wien',
      );

      // Act
      final firestoreData = beer.toFirestore();

      // Assert
      expect(firestoreData['name'], equals('Test Bier'));
      expect(firestoreData['country'], equals('🇦🇹 Österreich'));
      expect(firestoreData['percentage'], equals(5.0));
      expect(firestoreData['rating'], equals(8));
      expect(firestoreData['date'], isA<Timestamp>());
      expect(firestoreData['latitude'], equals(48.2082));
      expect(firestoreData['longitude'], equals(16.3738));
      expect(firestoreData['locationName'], equals('Wien'));
    });

    test('sollte hasLocation korrekt prüfen', () {
      // Arrange - Mit Standort
      final beerWithLocation = ConsumedBeer(
        name: 'Test Bier',
        country: '🇦🇹 Österreich',
        percentage: 5.0,
        rating: 8,
        date: testDate,
        latitude: 48.2082,
        longitude: 16.3738,
      );

      // Arrange - Ohne Standort
      final beerWithoutLocation = ConsumedBeer(
        name: 'Test Bier',
        country: '🇦🇹 Österreich',
        percentage: 5.0,
        rating: 8,
        date: testDate,
      );

      // Act & Assert
      expect(beerWithLocation.hasLocation(), isTrue);
      expect(beerWithoutLocation.hasLocation(), isFalse);
    });

    test('sollte getCountryEmoji korrekt extrahieren', () {
      // Arrange
      final beer = ConsumedBeer(
        name: 'Test Bier',
        country: '🇦🇹 Österreich',
        percentage: 5.0,
        rating: 8,
        date: testDate,
      );

      // Act
      final emoji = beer.getCountryEmoji();

      // Assert
      // Emoji sollte die ersten 2 Unicode-Zeichen sein
      expect(emoji.length, greaterThan(0));
      expect(emoji, isNotEmpty);
    });

    test('sollte getCountryName korrekt extrahieren', () {
      // Arrange
      final beer = ConsumedBeer(
        name: 'Test Bier',
        country: '🇦🇹 Österreich',
        percentage: 5.0,
        rating: 8,
        date: testDate,
      );

      // Act
      final countryName = beer.getCountryName();

      // Assert
      // Sollte den Namen ohne Emoji zurückgeben
      expect(countryName, isNotEmpty);
      expect(countryName, isNot(contains('🇦')));
      expect(countryName, isNot(contains('🇹')));
    });

    test('sollte copyWith korrekt funktionieren', () {
      // Arrange
      final originalBeer = ConsumedBeer(
        id: 'original-id',
        name: 'Original Bier',
        country: '🇦🇹 Österreich',
        percentage: 5.0,
        rating: 8,
        date: testDate,
      );

      // Act
      final copiedBeer = originalBeer.copyWith(
        name: 'Neues Bier',
        rating: 9,
      );

      // Assert
      expect(copiedBeer.id, equals('original-id')); // Unverändert
      expect(copiedBeer.name, equals('Neues Bier')); // Geändert
      expect(copiedBeer.rating, equals(9)); // Geändert
      expect(copiedBeer.country, equals('🇦🇹 Österreich')); // Unverändert
      expect(copiedBeer.percentage, equals(5.0)); // Unverändert
    });
  });
}
