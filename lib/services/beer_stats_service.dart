import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../models/consumed_beer.dart';
import '../core/utils/alcohol_calculator.dart';
import '../core/constants/app_constants.dart';
import '../repositories/beer_repository.dart';

class BeerStatsService {
  final BeerRepository _beerRepository = BeerRepository();

  /// Lädt alle Bier-Einträge als ConsumedBeer-Liste
  Future<List<ConsumedBeer>> getAllBeers() async {
    return await _beerRepository.getAllBeers();
  }

  /// Lädt alle Bier-Einträge als DocumentSnapshot-Liste (für Kompatibilität)
  Future<List<DocumentSnapshot>> getAllBeersAsSnapshots() async {
    final beers = await getAllBeers();
    // Konvertiere zurück zu DocumentSnapshots für bestehenden Code
    // Dies ist eine temporäre Lösung während der Migration
    return [];
  }

  /// Berechnet den heutigen Konsum
  Map<String, dynamic> getTodayConsumption(
    List<ConsumedBeer> beers,
    UserProfile? profile,
  ) {
    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);

    double totalAlcoholGrams = 0;
    int beerCount = 0;

    for (var beer in beers) {
      final dateKey = DateFormat('yyyy-MM-dd').format(beer.date);

      if (dateKey == todayKey) {
        beerCount++;
        totalAlcoholGrams += AlcoholCalculator.calculateAlcoholGrams(
          beer.percentage,
        );
      }
    }

    // Promille berechnen
    double maxPromille = 0;
    if (profile != null && totalAlcoholGrams > 0) {
      maxPromille = AlcoholCalculator.calculatePromille(
        totalAlcoholGrams,
        profile,
      );
    }

    return {
      'beerCount': beerCount,
      'alcoholGrams': totalAlcoholGrams,
      'promille': maxPromille,
    };
  }

  /// Legacy-Methode für DocumentSnapshot-Kompatibilität
  Map<String, dynamic> getTodayConsumptionFromSnapshots(
    List<DocumentSnapshot> beers,
    UserProfile? profile,
  ) {
    final consumedBeers = beers
        .map((doc) => ConsumedBeer.fromFirestore(doc))
        .toList();
    return getTodayConsumption(consumedBeers, profile);
  }

  /// Berechnet die höchste Promille mit Datum
  Map<String, dynamic>? getHighestPromille(
    List<ConsumedBeer> beers,
    UserProfile? profile,
  ) {
    if (profile == null || beers.isEmpty) return null;

    if (profile.weight <= 0) return null;

    final Map<String, List<ConsumedBeer>> beersByDay = {};
    for (var beer in beers) {
      final dateKey = DateFormat('yyyy-MM-dd').format(beer.date);
      beersByDay.putIfAbsent(dateKey, () => []).add(beer);
    }

    double maxPromille = 0;
    String? maxDate;

    beersByDay.forEach((dateKey, dailyBeers) {
      double dailyAlcoholGrams = 0;
      for (var beer in dailyBeers) {
        dailyAlcoholGrams += AlcoholCalculator.calculateAlcoholGrams(
          beer.percentage,
        );
      }

      final dailyPromille = AlcoholCalculator.calculateDailyPromille(
        dailyAlcoholGrams,
        profile,
      );

      if (dailyPromille > maxPromille) {
        maxPromille = dailyPromille;
        maxDate = dateKey;
      }
    });

    if (maxDate == null) return null;

    return {
      'promille': maxPromille,
      'date': maxDate!,
      'formattedDate': _formatDate(maxDate!),
    };
  }

  /// Legacy-Methode für DocumentSnapshot-Kompatibilität
  Map<String, dynamic>? getHighestPromilleFromSnapshots(
    List<DocumentSnapshot> beers,
    UserProfile? profile,
  ) {
    final consumedBeers = beers
        .map((doc) => ConsumedBeer.fromFirestore(doc))
        .toList();
    return getHighestPromille(consumedBeers, profile);
  }

  /// Findet das meist getrunkene Getränk
  Map<String, dynamic>? getMostConsumedBeer(List<ConsumedBeer> beers) {
    if (beers.isEmpty) return null;

    final Map<String, int> beerCounts = {};

    for (var beer in beers) {
      beerCounts[beer.name] = (beerCounts[beer.name] ?? 0) + 1;
    }

    if (beerCounts.isEmpty) return null;

    final mostConsumed = beerCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return {
      'name': mostConsumed.key,
      'count': mostConsumed.value,
    };
  }

  /// Legacy-Methode für DocumentSnapshot-Kompatibilität
  Map<String, dynamic>? getMostConsumedBeerFromSnapshots(
    List<DocumentSnapshot> beers,
  ) {
    final consumedBeers = beers
        .map((doc) => ConsumedBeer.fromFirestore(doc))
        .toList();
    return getMostConsumedBeer(consumedBeers);
  }

  /// Berechnet den Gesamtkonsum dieser Woche
  Map<String, dynamic> getWeekConsumption(
    List<ConsumedBeer> beers,
    UserProfile? profile,
  ) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    int beerCount = 0;
    double totalAlcoholGrams = 0;

    for (var beer in beers) {
      if (beer.date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        beerCount++;
        totalAlcoholGrams += AlcoholCalculator.calculateAlcoholGrams(
          beer.percentage,
        );
      }
    }

    return {
      'beerCount': beerCount,
      'alcoholGrams': totalAlcoholGrams,
    };
  }

  /// Legacy-Methode für DocumentSnapshot-Kompatibilität
  Map<String, dynamic> getWeekConsumptionFromSnapshots(
    List<DocumentSnapshot> beers,
    UserProfile? profile,
  ) {
    final consumedBeers = beers
        .map((doc) => ConsumedBeer.fromFirestore(doc))
        .toList();
    return getWeekConsumption(consumedBeers, profile);
  }

  /// Berechnet den Durchschnitt pro Tag (letzte 30 Tage)
  Map<String, dynamic> getAveragePerDay(List<ConsumedBeer> beers) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final Map<String, int> beersByDay = {};

    for (var beer in beers) {
      if (beer.date.isAfter(thirtyDaysAgo.subtract(const Duration(days: 1)))) {
        final dateKey = DateFormat('yyyy-MM-dd').format(beer.date);
        beersByDay[dateKey] = (beersByDay[dateKey] ?? 0) + 1;
      }
    }

    final activeDays = beersByDay.length;
    final totalBeers = beersByDay.values.fold(0, (a, b) => a + b);

    return {
      'activeDays': activeDays,
      'totalBeers': totalBeers,
      'averagePerDay': activeDays > 0 ? (totalBeers / activeDays) : 0.0,
    };
  }

  /// Legacy-Methode für DocumentSnapshot-Kompatibilität
  Map<String, dynamic> getAveragePerDayFromSnapshots(
    List<DocumentSnapshot> beers,
  ) {
    final consumedBeers = beers
        .map((doc) => ConsumedBeer.fromFirestore(doc))
        .toList();
    return getAveragePerDay(consumedBeers);
  }

  /// Gibt die Gesamtanzahl der Biere zurück
  int getTotalBeers(List<ConsumedBeer> beers) {
    return beers.length;
  }

  /// Legacy-Methode für DocumentSnapshot-Kompatibilität
  int getTotalBeersFromSnapshots(List<DocumentSnapshot> beers) {
    return beers.length;
  }

  String _formatDate(String dateKey) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateKey);
      return DateFormat('dd.MM.yyyy', 'de').format(date);
    } catch (e) {
      return dateKey;
    }
  }
}

