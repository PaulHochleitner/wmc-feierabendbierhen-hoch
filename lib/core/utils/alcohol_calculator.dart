import '../constants/app_constants.dart';
import '../../models/user_profile.dart';

/// Utility-Klasse für Alkoholberechnungen
class AlcoholCalculator {
  AlcoholCalculator._(); // Privater Konstruktor

  /// Berechnet die Alkoholmenge in Gramm für ein Bier
  /// 
  /// [alcoholPercentage] - Alkoholgehalt in Prozent (z.B. 5.0 für 5%)
  /// [volumeMl] - Volumen in ml (Standard: 500ml)
  static double calculateAlcoholGrams(
    double alcoholPercentage, {
    double volumeMl = AppConstants.standardBeerVolumeMl,
  }) {
    return volumeMl * (alcoholPercentage / 100.0) * AppConstants.alcoholDensity;
  }

  /// Berechnet den Promillewert basierend auf Alkoholmenge und Profil
  /// 
  /// [alcoholGrams] - Alkoholmenge in Gramm
  /// [profile] - User-Profil mit Gewicht und Geschlecht
  static double calculatePromille(double alcoholGrams, UserProfile profile) {
    if (profile.weight <= 0) return 0.0;

    final distributionFactor = profile.gender == AppConstants.genderFemale
        ? AppConstants.femaleAlcoholDistributionFactor
        : AppConstants.maleAlcoholDistributionFactor;

    return alcoholGrams / (profile.weight * distributionFactor);
  }

  /// Berechnet den Promillewert für mehrere Biere an einem Tag
  /// 
  /// [dailyAlcoholGrams] - Gesamtalkoholmenge des Tages in Gramm
  /// [profile] - User-Profil mit Gewicht und Geschlecht
  static double calculateDailyPromille(
    double dailyAlcoholGrams,
    UserProfile profile,
  ) {
    return calculatePromille(dailyAlcoholGrams, profile);
  }
}
