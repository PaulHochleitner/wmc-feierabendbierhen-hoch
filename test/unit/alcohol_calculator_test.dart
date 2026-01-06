import 'package:flutter_test/flutter_test.dart';
import 'package:feierabendbierchen_flutter/core/utils/alcohol_calculator.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:feierabendbierchen_flutter/core/constants/app_constants.dart';

void main() {
  group('AlcoholCalculator', () {
    group('calculateAlcoholGrams', () {
      test('sollte korrekt Alkohol in Gramm für Standard-Bier berechnen', () {
        // Arrange
        const alcoholPercentage = 5.0; // 5% Alkohol
        const expectedVolume = 500.0; // 500ml
        const expectedDensity = 0.8; // g/ml

        // Act
        final result = AlcoholCalculator.calculateAlcoholGrams(
          alcoholPercentage,
        );

        // Assert
        // Formel: 500ml * (5% / 100) * 0.8 = 20g
        final expected = expectedVolume * (alcoholPercentage / 100.0) * expectedDensity;
        expect(result, equals(expected));
        expect(result, equals(20.0));
      });

      test('sollte korrekt Alkohol für unterschiedliche Volumina berechnen', () {
        // Arrange
        const alcoholPercentage = 5.0;
        const customVolume = 330.0; // 330ml Flasche

        // Act
        final result = AlcoholCalculator.calculateAlcoholGrams(
          alcoholPercentage,
          volumeMl: customVolume,
        );

        // Assert
        // Formel: 330ml * (5% / 100) * 0.8 = 13.2g
        expect(result, closeTo(13.2, 0.001));
      });

      test('sollte korrekt für hohen Alkoholgehalt berechnen', () {
        // Arrange
        const alcoholPercentage = 8.5; // Starkbier

        // Act
        final result = AlcoholCalculator.calculateAlcoholGrams(
          alcoholPercentage,
        );

        // Assert
        // Formel: 500ml * (8.5% / 100) * 0.8 = 34g
        expect(result, equals(34.0));
      });
    });

    group('calculatePromille', () {
      test('sollte korrekt Promille für männlichen User berechnen', () {
        // Arrange
        const alcoholGrams = 20.0; // 1 Bier (5%, 500ml)
        final profile = UserProfile(
          userId: 'test-user',
          name: 'Test User',
          weight: 80.0, // 80kg
          height: 180.0,
          gender: AppConstants.genderMale,
        );

        // Act
        final result = AlcoholCalculator.calculatePromille(
          alcoholGrams,
          profile,
        );

        // Assert
        // Formel: 20g / (80kg * 0.68) = 20 / 54.4 ≈ 0.368‰
        final expected = alcoholGrams / (profile.weight * AppConstants.maleAlcoholDistributionFactor);
        expect(result, closeTo(expected, 0.001));
        expect(result, closeTo(0.368, 0.01));
      });

      test('sollte korrekt Promille für weiblichen User berechnen', () {
        // Arrange
        const alcoholGrams = 20.0; // 1 Bier (5%, 500ml)
        final profile = UserProfile(
          userId: 'test-user',
          name: 'Test User',
          weight: 65.0, // 65kg
          height: 165.0,
          gender: AppConstants.genderFemale,
        );

        // Act
        final result = AlcoholCalculator.calculatePromille(
          alcoholGrams,
          profile,
        );

        // Assert
        // Formel: 20g / (65kg * 0.55) = 20 / 35.75 ≈ 0.559‰
        final expected = alcoholGrams / (profile.weight * AppConstants.femaleAlcoholDistributionFactor);
        expect(result, closeTo(expected, 0.001));
        expect(result, closeTo(0.559, 0.01));
      });

      test('sollte 0.0 zurückgeben wenn Gewicht <= 0', () {
        // Arrange
        const alcoholGrams = 20.0;
        final profile = UserProfile(
          userId: 'test-user',
          name: 'Test User',
          weight: 0.0, // Ungültiges Gewicht
          height: 180.0,
          gender: AppConstants.genderMale,
        );

        // Act
        final result = AlcoholCalculator.calculatePromille(
          alcoholGrams,
          profile,
        );

        // Assert
        expect(result, equals(0.0));
      });
    });

    group('calculateDailyPromille', () {
      test('sollte korrekt Tages-Promille berechnen', () {
        // Arrange
        const dailyAlcoholGrams = 60.0; // 3 Biere
        final profile = UserProfile(
          userId: 'test-user',
          name: 'Test User',
          weight: 75.0,
          height: 175.0,
          gender: AppConstants.genderMale,
        );

        // Act
        final result = AlcoholCalculator.calculateDailyPromille(
          dailyAlcoholGrams,
          profile,
        );

        // Assert
        // Formel: 60g / (75kg * 0.68) = 60 / 51 ≈ 1.176‰
        final expected = dailyAlcoholGrams / (profile.weight * AppConstants.maleAlcoholDistributionFactor);
        expect(result, closeTo(expected, 0.001));
      });
    });
  });
}
