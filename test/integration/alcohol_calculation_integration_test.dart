import 'package:flutter_test/flutter_test.dart';
import 'package:feierabendbierchen_flutter/core/utils/alcohol_calculator.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:feierabendbierchen_flutter/core/constants/app_constants.dart';

/// Integration-Test für die gesamte Alkoholberechnungs-Pipeline
/// Testet die Zusammenarbeit zwischen AlcoholCalculator und UserProfile
void main() {
  group('Alcohol Calculation Integration Tests', () {
    test('sollte vollständige Berechnungskette korrekt durchführen', () {
      // Arrange - Realistisches Szenario
      final profile = UserProfile(
        userId: 'test-user',
        name: 'Test User',
        weight: 80.0, // 80kg
        height: 180.0,
        gender: AppConstants.genderMale,
      );

      const beer1Percentage = 5.0; // Standard-Bier
      const beer2Percentage = 6.5; // Starkbier
      const beer3Percentage = 5.0; // Standard-Bier

      // Act - Schritt 1: Alkohol in Gramm für jedes Bier
      final alcoholGrams1 = AlcoholCalculator.calculateAlcoholGrams(beer1Percentage);
      final alcoholGrams2 = AlcoholCalculator.calculateAlcoholGrams(beer2Percentage);
      final alcoholGrams3 = AlcoholCalculator.calculateAlcoholGrams(beer3Percentage);

      // Schritt 2: Gesamtalkohol
      final totalAlcoholGrams = alcoholGrams1 + alcoholGrams2 + alcoholGrams3;

      // Schritt 3: Promille berechnen
      final promille = AlcoholCalculator.calculatePromille(
        totalAlcoholGrams,
        profile,
      );

      // Assert
      expect(alcoholGrams1, equals(20.0)); // 500ml * 5% * 0.8 = 20g
      expect(alcoholGrams2, equals(26.0)); // 500ml * 6.5% * 0.8 = 26g
      expect(alcoholGrams3, equals(20.0)); // 500ml * 5% * 0.8 = 20g
      expect(totalAlcoholGrams, equals(66.0)); // Gesamt: 66g

      // Promille: 66g / (80kg * 0.68) ≈ 1.213‰
      expect(promille, closeTo(1.213, 0.01));
    });

    test('sollte Geschlechter-Unterschied korrekt berücksichtigen', () {
      // Arrange
      const alcoholGrams = 40.0; // 2 Biere
      final maleProfile = UserProfile(
        userId: 'male-user',
        name: 'Male User',
        weight: 75.0,
        height: 180.0,
        gender: AppConstants.genderMale,
      );
      final femaleProfile = UserProfile(
        userId: 'female-user',
        name: 'Female User',
        weight: 75.0, // Gleiches Gewicht
        height: 165.0,
        gender: AppConstants.genderFemale,
      );

      // Act
      final malePromille = AlcoholCalculator.calculatePromille(
        alcoholGrams,
        maleProfile,
      );
      final femalePromille = AlcoholCalculator.calculatePromille(
        alcoholGrams,
        femaleProfile,
      );

      // Assert
      // Weibliche User sollten höhere Promille haben (niedrigerer Verteilungsfaktor)
      expect(femalePromille, greaterThan(malePromille));
      expect(malePromille, closeTo(0.784, 0.01)); // 40g / (75kg * 0.68)
      expect(femalePromille, closeTo(0.970, 0.01)); // 40g / (75kg * 0.55)
    });

    test('sollte Edge Cases korrekt behandeln', () {
      // Arrange
      final profile = UserProfile(
        userId: 'test-user',
        name: 'Test User',
        weight: 100.0,
        height: 190.0,
        gender: AppConstants.genderMale,
      );

      // Act & Assert - Null Alkohol
      final zeroPromille = AlcoholCalculator.calculatePromille(0.0, profile);
      expect(zeroPromille, equals(0.0));

      // Act & Assert - Sehr hoher Alkoholgehalt
      const highAlcohol = 100.0; // 100g Alkohol
      final highPromille = AlcoholCalculator.calculatePromille(highAlcohol, profile);
      expect(highPromille, greaterThan(1.0)); // Sollte über 1‰ sein
    });
  });
}
