import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feierabendbierchen_flutter/services/beer_stats_service.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:intl/intl.dart';
import 'package:feierabendbierchen_flutter/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BeerStatsService _statsService = BeerStatsService();
  final BeerFirestoreService _firestoreService = BeerFirestoreService();
  
  bool _isLoading = true;
  List<DocumentSnapshot> _beers = [];
  UserProfile? _userProfile;
  
  // Heutiger Konsum
  Map<String, dynamic>? _todayConsumption;
  
  // Statistiken
  Map<String, dynamic>? _highestPromille;
  Map<String, dynamic>? _mostConsumedBeer;
  Map<String, dynamic>? _weekConsumption;
  Map<String, dynamic>? _averagePerDay;
  int _totalBeers = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _firestoreService.getUserProfile();
      final beers = await _statsService.getAllBeers();
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _beers = beers;
          _calculateStats();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateStats() {
    _todayConsumption = _statsService.getTodayConsumption(_beers, _userProfile);
    _highestPromille = _statsService.getHighestPromille(_beers, _userProfile);
    _mostConsumedBeer = _statsService.getMostConsumedBeer(_beers);
    _weekConsumption = _statsService.getWeekConsumption(_beers, _userProfile);
    _averagePerDay = _statsService.getAveragePerDay(_beers);
    _totalBeers = _statsService.getTotalBeers(_beers);
  }

  @override
  Widget build(BuildContext context) {
    // Bottom Navigation Bar Höhe
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: const Color(0xFFFFD700)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFFFD700),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Heutiger Konsum - Prominent
            if (_todayConsumption != null && _todayConsumption!['beerCount'] > 0)
              _buildTodayConsumptionCard(),
            if (_todayConsumption == null || _todayConsumption!['beerCount'] == 0)
              _buildNoConsumptionTodayCard(),
            const SizedBox(height: 20),
            
            // Quick Stats Grid
            _buildQuickStatsGrid(),
            const SizedBox(height: 24),
            
            // Statistiken nur anzeigen wenn Daten vorhanden
            if (_totalBeers > 0) ...[
              // Höchste Promille
              if (_highestPromille != null)
                _buildStatCard(
                  title: AppLocalizations.of(context).t('highest_promille'),
                  value: '${_highestPromille!['promille'].toStringAsFixed(2)} ‰',
                  subtitle: _highestPromille!['formattedDate'],
                  icon: Icons.trending_up,
                  color: Colors.redAccent,
                ),
              if (_highestPromille != null) const SizedBox(height: 16),
              
              // Meist getrunkenes Getränk
              if (_mostConsumedBeer != null)
                _buildStatCard(
                  title: AppLocalizations.of(context).t('most_consumed_drink'),
                  value: _mostConsumedBeer!['name'],
                  subtitle: '${_mostConsumedBeer!['count']}${AppLocalizations.of(context).t('times_drunk')}',
                  icon: Icons.local_drink,
                  color: const Color(0xFFFFD700),
                ),
              if (_mostConsumedBeer != null) const SizedBox(height: 16),
              
              // Diese Woche
              if (_weekConsumption != null && _weekConsumption!['beerCount'] > 0)
                _buildStatCard(
                  title: AppLocalizations.of(context).t('this_week'),
                  value: '${_weekConsumption!['beerCount']} ${AppLocalizations.of(context).t('beers')}',
                  subtitle: '${_weekConsumption!['alcoholGrams'].toStringAsFixed(1)} ${AppLocalizations.of(context).t('g_alcohol')}',
                  icon: Icons.calendar_today,
                  color: Colors.blueAccent,
                ),
              if (_weekConsumption != null && _weekConsumption!['beerCount'] > 0) const SizedBox(height: 16),
              
              // Durchschnitt
              if (_averagePerDay != null && _averagePerDay!['activeDays'] > 0)
                _buildStatCard(
                  title: AppLocalizations.of(context).t('average_30_days'),
                  value: '${_averagePerDay!['averagePerDay'].toStringAsFixed(1)} ${AppLocalizations.of(context).t('beers_per_day')}',
                  subtitle: '${_averagePerDay!['activeDays']} ${AppLocalizations.of(context).t('active_days')}',
                  icon: Icons.bar_chart,
                  color: Colors.greenAccent,
                ),
              if (_averagePerDay != null && _averagePerDay!['activeDays'] > 0) const SizedBox(height: 16),
              
              // Gesamt
              _buildStatCard(
                title: AppLocalizations.of(context).t('total'),
                value: '$_totalBeers ${AppLocalizations.of(context).t('beers')}',
                subtitle: AppLocalizations.of(context).t('total_drunk'),
                icon: Icons.emoji_events,
                color: const Color(0xFFFFD700),
              ),
            ] else ...[
              // Keine Daten
              _buildEmptyState(),
            ],
            const SizedBox(height: 20),
            
            // Info wenn kein Profil
            if (_userProfile == null)
              _buildNoProfileInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).t('welcome'),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, d. MMMM yyyy', 'de').format(DateTime.now()),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayConsumptionCard() {
    final consumption = _todayConsumption!;
    final beerCount = consumption['beerCount'] as int;
    final promille = consumption['promille'] as double;
    final alcoholGrams = consumption['alcoholGrams'] as double;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFFA000).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.today,
                  color: Color(0xFFFFD700),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).t('todays_consumption'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$beerCount ${beerCount == 1 ? AppLocalizations.of(context).t('beer_singular') : AppLocalizations.of(context).t('beers')}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  AppLocalizations.of(context).t('promille'),
                  '${promille.toStringAsFixed(2)} ‰',
                  Icons.speed,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[700],
              ),
              Expanded(
                child: _buildMiniStat(
                  AppLocalizations.of(context).t('alcohol'),
                  '${alcoholGrams.toStringAsFixed(1)} g',
                  Icons.science,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            AppLocalizations.of(context).t('total'),
            '$_totalBeers',
            Icons.local_drink,
            Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            AppLocalizations.of(context).t('this_week'),
            '${_weekConsumption?['beerCount'] ?? 0}',
            Icons.calendar_today,
            Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1917),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1917),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoConsumptionTodayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1917).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[700]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_drink_outlined,
            color: Colors.grey[600],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).t('no_consumption_today'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).t('add_first_beer'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1917).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[700]!.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_drink_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).t('no_data'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).t('add_beer_for_stats'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProfileInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1917).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).t('create_profile_info'),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
