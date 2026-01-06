import 'package:flutter_test/flutter_test.dart';
import 'package:feierabendbierchen_flutter/core/data/beer_database.dart';

void main() {
  group('BeerDatabase', () {
    test('sollte alle Länder zurückgeben', () {
      // Act
      final countries = BeerDatabase.getCountries();

      // Assert
      expect(countries, isNotEmpty);
      expect(countries.length, greaterThanOrEqualTo(4));
      expect(countries, contains('🇦🇹 Österreich'));
      expect(countries, contains('🇩🇪 Deutschland'));
      expect(countries, contains('🇳🇱 Niederlande'));
      expect(countries, contains('🇭🇷 Kroatien'));
      // Länder sollten sortiert sein
      expect(countries, orderedEquals(countries.toList()..sort()));
    });

    test('sollte Biere für ein Land zurückgeben', () {
      // Act
      final austrianBeers = BeerDatabase.getBeersByCountry('🇦🇹 Österreich');

      // Assert
      expect(austrianBeers, isNotNull);
      expect(austrianBeers, isNotEmpty);
      expect(austrianBeers!.first, containsPair('name', isA<String>()));
      expect(austrianBeers.first, containsPair('alc', isA<double>()));
    });

    test('sollte null zurückgeben für unbekanntes Land', () {
      // Act
      final beers = BeerDatabase.getBeersByCountry('🇺🇸 USA');

      // Assert
      expect(beers, isNull);
    });

    test('sollte Bier nach Name und Land finden', () {
      // Act
      final beer = BeerDatabase.findBeer(
        '🇦🇹 Österreich',
        'Gösser Export (Dortmunder Export)',
      );

      // Assert
      expect(beer, isNotNull);
      expect(beer!['name'], equals('Gösser Export (Dortmunder Export)'));
      expect(beer['alc'], equals(5.0));
    });

    test('sollte null zurückgeben wenn Bier nicht gefunden', () {
      // Act
      final beer = BeerDatabase.findBeer(
        '🇦🇹 Österreich',
        'Nicht existierendes Bier',
      );

      // Assert
      expect(beer, isNull);
    });

    test('sollte null zurückgeben wenn Land nicht existiert', () {
      // Act
      final beer = BeerDatabase.findBeer(
        '🇺🇸 USA',
        'Irgendein Bier',
      );

      // Assert
      expect(beer, isNull);
    });
  });
}
