import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';

class BeerStatsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // Lade alle Bier-Einträge
  Future<List<DocumentSnapshot>> getAllBeers() async {
    if (userId == null) return [];
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('beers')
          .orderBy('date', descending: false)
          .get();
      return snapshot.docs;
    } catch (e) {
      return [];
    }
  }

  // Berechne heutigen Konsum
  Map<String, dynamic> getTodayConsumption(List<DocumentSnapshot> beers, UserProfile? profile) {
    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);
    
    double totalAlcoholGrams = 0;
    int beerCount = 0;
    double maxPromille = 0;
    
    for (var doc in beers) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      
      if (dateKey == todayKey) {
        beerCount++;
        double alc = (data['percentage'] ?? 0.0).toDouble();
        totalAlcoholGrams += 500 * (alc / 100.0) * 0.8;
      }
    }
    
    // Promille berechnen
    if (profile != null && totalAlcoholGrams > 0) {
      double r = profile.gender == 'female' ? 0.55 : 0.68;
      double weight = profile.weight;
      if (weight > 0) {
        maxPromille = totalAlcoholGrams / (weight * r);
      }
    }
    
    return {
      'beerCount': beerCount,
      'alcoholGrams': totalAlcoholGrams,
      'promille': maxPromille,
    };
  }

  // Höchste Promille mit Datum
  Map<String, dynamic>? getHighestPromille(List<DocumentSnapshot> beers, UserProfile? profile) {
    if (profile == null || beers.isEmpty) return null;
    
    double r = profile.gender == 'female' ? 0.55 : 0.68;
    double weight = profile.weight;
    if (weight <= 0) return null;
    
    Map<String, List<DocumentSnapshot>> beersByDay = {};
    for (var doc in beers) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      beersByDay.putIfAbsent(dateKey, () => []).add(doc);
    }
    
    double maxPromille = 0;
    String? maxDate;
    
    beersByDay.forEach((dateKey, dailyBeers) {
      double dailyAlcoholGrams = 0;
      for (var doc in dailyBeers) {
        final data = doc.data() as Map<String, dynamic>;
        double alc = (data['percentage'] ?? 0.0).toDouble();
        dailyAlcoholGrams += 500 * (alc / 100.0) * 0.8;
      }
      
      double dailyPromille = dailyAlcoholGrams / (weight * r);
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

  // Meist getrunkenes Getränk
  Map<String, dynamic>? getMostConsumedBeer(List<DocumentSnapshot> beers) {
    if (beers.isEmpty) return null;
    
    Map<String, int> beerCounts = {};
    
    for (var doc in beers) {
      final data = doc.data() as Map<String, dynamic>;
      String name = data['name'] ?? 'Unbekannt';
      beerCounts[name] = (beerCounts[name] ?? 0) + 1;
    }
    
    if (beerCounts.isEmpty) return null;
    
    String mostConsumed = beerCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    int count = beerCounts[mostConsumed]!;
    
    return {
      'name': mostConsumed,
      'count': count,
    };
  }

  // Gesamtkonsum diese Woche
  Map<String, dynamic> getWeekConsumption(List<DocumentSnapshot> beers, UserProfile? profile) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    int beerCount = 0;
    double totalAlcoholGrams = 0;
    
    for (var doc in beers) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      
      if (date.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        beerCount++;
        double alc = (data['percentage'] ?? 0.0).toDouble();
        totalAlcoholGrams += 500 * (alc / 100.0) * 0.8;
      }
    }
    
    return {
      'beerCount': beerCount,
      'alcoholGrams': totalAlcoholGrams,
    };
  }

  // Durchschnitt pro Tag (letzte 30 Tage)
  Map<String, dynamic> getAveragePerDay(List<DocumentSnapshot> beers) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    Map<String, int> beersByDay = {};
    
    for (var doc in beers) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      
      if (date.isAfter(thirtyDaysAgo.subtract(const Duration(days: 1)))) {
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        beersByDay[dateKey] = (beersByDay[dateKey] ?? 0) + 1;
      }
    }
    
    int activeDays = beersByDay.length;
    int totalBeers = beersByDay.values.fold(0, (a, b) => a + b);
    
    return {
      'activeDays': activeDays,
      'totalBeers': totalBeers,
      'averagePerDay': activeDays > 0 ? (totalBeers / activeDays) : 0.0,
    };
  }

  // Gesamtanzahl Biere
  int getTotalBeers(List<DocumentSnapshot> beers) {
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

