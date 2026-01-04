import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';

class StatistikPage extends StatefulWidget {
  const StatistikPage({super.key});

  @override
  State<StatistikPage> createState() => _StatistikPageState();
}

class _StatistikPageState extends State<StatistikPage> {
  final BeerFirestoreService _firestoreService = BeerFirestoreService();
  bool _isLoading = true;
  List<DocumentSnapshot> _beers = [];
  UserProfile? _userProfile;

  // Stats
  int _totalBeers = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _mostBeersOneDay = 0;
  
  double _avgAlcoholPerDay = 0.0;
  double _avgAlcoholPerWeek = 0.0;
  double _avgAlcoholPerMonth = 0.0;
  double _maxAlcoholOneDay = 0.0;
  
  double _avgPromille = 0.0;
  double _maxPromilleRecord = 0.0;
  double _avgDailyPeakPromille = 0.0;

  // Chart Data
  Map<int, double> _last7DaysBeers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final profile = await _firestoreService.getUserProfile();
      final beersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('beers')
          .orderBy('date', descending: false) // Oldest first for streak calc
          .get();

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _beers = beersSnapshot.docs;
          _calculateStats();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading stats: $e");
    }
  }

  void _calculateStats() {
    if (_beers.isEmpty) return;

    _totalBeers = _beers.length;

    // Group by Day
    Map<String, List<DocumentSnapshot>> beersByDay = {};
    for (var doc in _beers) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      beersByDay.putIfAbsent(dateKey, () => []).add(doc);
    }

    // 1. Streaks & Most Beers
    int currentRun = 0;
    int maxRun = 0;
    int maxBeers = 0;
    
    // Sort dates
    List<String> sortedDates = beersByDay.keys.toList()..sort();
    
    for (int i = 0; i < sortedDates.length; i++) {
      // Most Beers
      int dailyCount = beersByDay[sortedDates[i]]!.length;
      if (dailyCount > maxBeers) maxBeers = dailyCount;

      // Streak
      DateTime currentDate = DateFormat('yyyy-MM-dd').parse(sortedDates[i]);
      if (i > 0) {
        DateTime prevDate = DateFormat('yyyy-MM-dd').parse(sortedDates[i - 1]);
        if (currentDate.difference(prevDate).inDays == 1) {
          currentRun++;
        } else {
          if (currentRun > maxRun) maxRun = currentRun;
          currentRun = 1;
        }
      } else {
        currentRun = 1;
      }
    }
    if (currentRun > maxRun) maxRun = currentRun;

    // Check if streak is active (last beer was today or yesterday)
    DateTime lastBeerDate = DateFormat('yyyy-MM-dd').parse(sortedDates.last);
    DateTime today = DateTime.now();
    DateTime yesterday = today.subtract(const Duration(days: 1));
    
    bool isStreakActive = lastBeerDate.year == today.year && lastBeerDate.month == today.month && lastBeerDate.day == today.day ||
                          lastBeerDate.year == yesterday.year && lastBeerDate.month == yesterday.month && lastBeerDate.day == yesterday.day;

    _currentStreak = isStreakActive ? currentRun : 0;
    _longestStreak = maxRun;
    _mostBeersOneDay = maxBeers;

    // 2. Alcohol & Promille
    double totalAlcoholGrams = 0;
    double totalPromillePeaks = 0;
    double maxPromille = 0;
    double maxAlcoholDay = 0;

    beersByDay.forEach((key, dailyBeers) {
      double dailyAlcoholGrams = 0;
      for (var doc in dailyBeers) {
        final data = doc.data() as Map<String, dynamic>;
        double alc = (data['percentage'] ?? 0.0).toDouble();
        // Formula: 500ml * (alc / 100) * 0.8
        dailyAlcoholGrams += 500 * (alc / 100.0) * 0.8;
      }

      if (dailyAlcoholGrams > maxAlcoholDay) maxAlcoholDay = dailyAlcoholGrams;
      totalAlcoholGrams += dailyAlcoholGrams;

      // Promille for this day
      if (_userProfile != null) {
        double r = _userProfile!.gender == 'female' ? 0.55 : 0.68;
        double weight = _userProfile!.weight;
        if (weight > 0) {
          double dailyPromille = dailyAlcoholGrams / (weight * r);
          totalPromillePeaks += dailyPromille;
          if (dailyPromille > maxPromille) maxPromille = dailyPromille;
        }
      }
    });

    int totalDays = beersByDay.length; // Active drinking days
    // Or total days since first beer? Usually stats are per active day or total timeframe.
    // Let's do average per active drinking day for "Avg Promille" to make it meaningful.
    
    _maxAlcoholOneDay = maxAlcoholDay;
    _avgAlcoholPerDay = totalDays > 0 ? totalAlcoholGrams / totalDays : 0;
    _avgAlcoholPerWeek = _avgAlcoholPerDay * 7;
    _avgAlcoholPerMonth = _avgAlcoholPerDay * 30;

    _maxPromilleRecord = maxPromille;
    _avgDailyPeakPromille = totalDays > 0 ? totalPromillePeaks / totalDays : 0;
    _avgPromille = _avgDailyPeakPromille; // Using avg peak as "Average Promille"

    // 3. Chart Data (Last 7 Days)
    _last7DaysBeers = {};
    DateTime now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      DateTime d = now.subtract(Duration(days: i));
      String dKey = DateFormat('yyyy-MM-dd').format(d);
      _last7DaysBeers[6 - i] = (beersByDay[dKey]?.length ?? 0).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF12100E),
      appBar: AppBar(
        title: const Text("KONSUM STATISTIK"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: const Color(0xFFFFD700),
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Streak & Records
            Row(
              children: [
                Expanded(child: _buildStatCard("STREAK", "$_currentStreak Tage", Icons.local_fire_department, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard("REKORD", "$_mostBeersOneDay Biere", Icons.emoji_events, const Color(0xFFFFD700))),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Chart
            Text(
              "BIERE (LETZTE 7 TAGE)",
              style: TextStyle(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_last7DaysBeers.values.fold(0.0, (p, c) => p > c ? p : c)) + 2,
                  barTouchData: BarTouchData(enabled: true),
                  gridData: FlGridData(
                    show: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final now = DateTime.now();
                          final date = now.subtract(Duration(days: (6 - value).toInt()));
                          return Text(
                            DateFormat('E', 'de').format(date).substring(0, 2),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    7,
                    (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: _last7DaysBeers[i] ?? 0.0,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                          color: const Color(0xFFFFD700),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: (_last7DaysBeers.values.fold(0.0, (p, c) => p > c ? p : c)) + 2,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 3. Alcohol Stats
            _buildSectionHeader("ALKOHOL KONSUM (REIN)"),
            _buildInfoRow("Ø pro Tag", "${_avgAlcoholPerDay.toStringAsFixed(1)} g"),
            _buildInfoRow("Ø pro Woche", "${_avgAlcoholPerWeek.toStringAsFixed(1)} g"),
            _buildInfoRow("Ø pro Monat", "${_avgAlcoholPerMonth.toStringAsFixed(1)} g"),
            _buildInfoRow("Maximal (1 Tag)", "${_maxAlcoholOneDay.toStringAsFixed(1)} g"),
            
            const SizedBox(height: 32),

            // 4. Promille Stats
            _buildSectionHeader("PROMILLE WERTE (GESCHÄTZT)"),
            _buildInfoRow("Ø Max. Promille / Tag", "${_avgDailyPeakPromille.toStringAsFixed(2)} ‰"),
            _buildInfoRow("Höchster Wert (Rekord)", "${_maxPromilleRecord.toStringAsFixed(2)} ‰", highlight: true),
            
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Berechnung: 500ml * Vol% * 0.8 / (Gewicht * r)",
                style: TextStyle(color: Colors.grey[700], fontSize: 10),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1B16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8D6E63).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1917),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? const Color(0xFFFFD700) : const Color(0xFF8D6E63).withOpacity(0.2),
          width: highlight ? 1 : 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFFFFD700) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: highlight ? [Shadow(color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 8)] : [],
            ),
          ),
        ],
      ),
    );
  }
}
