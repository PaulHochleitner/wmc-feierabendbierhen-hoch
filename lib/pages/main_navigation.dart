// lib/pages/main_navigation.dart (umbenennen von MyHomePage)
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:feierabendbierchen_flutter/pages/home/home_page.dart';
import 'package:feierabendbierchen_flutter/pages/consumption/consumption_diary_page.dart';
import 'package:feierabendbierchen_flutter/pages/statistik/statisitk_page.dart';
import 'package:feierabendbierchen_flutter/pages/profile/profile_page.dart';
import 'package:feierabendbierchen_flutter/pages/profile/custom_login_page.dart';
import 'package:feierabendbierchen_flutter/l10n/app_localizations.dart';
import 'package:feierabendbierchen_flutter/pages/profile/user_profile_setup_page.dart';
import 'package:feierabendbierchen_flutter/pages/settings/settings_page.dart';

class MyHomePage extends StatefulWidget {
  final bool isLoggedIn;
  final bool isGuestMode;

  const MyHomePage({
    super.key,
    required this.isLoggedIn,
    this.isGuestMode = false,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // ===== NEU: Profil-Verwaltung =====
  final BeerFirestoreService _firestoreService = BeerFirestoreService();
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;
  bool _needsProfileSetup = false;

  // Animation für Navbar
  late AnimationController _controller;
  final List<Bubble> _bubbles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    for (int i = 0; i < 20; i++) {
      _bubbles.add(
        Bubble(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 2 + _random.nextDouble() * 4,
          speed: 0.3 + _random.nextDouble() * 0.7,
        ),
      );
    }

    // ===== NEU: Profil beim Start laden =====
    if (widget.isLoggedIn) {
      _checkUserProfile();
    } else {
      setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ===== NEU: Profil-Check Methode =====
  Future<void> _checkUserProfile() async {
    setState(() => _isLoadingProfile = true);

    UserProfile? profile = await _firestoreService.getUserProfile();

    if (profile == null && FirebaseAuth.instance.currentUser != null) {
      // ✅ Profil existiert nicht → zeige Setup-Seite
      setState(() {
        _needsProfileSetup = true;
        _isLoadingProfile = false;
      });
    } else {
      // ✅ Profil existiert → zeige normale App
      setState(() {
        _userProfile = profile;
        _needsProfileSetup = false;
        _isLoadingProfile = false;
      });
    }
  }

  // ===== NEU: Callback wenn Profil erstellt wurde =====
  void _onProfileComplete() {
    // Nach Profil-Setup neu laden
    _checkUserProfile();
  }

  void _showProfileSetupIfNeeded() {
    if (_needsProfileSetup && widget.isLoggedIn && !_isLoadingProfile) {
      // Zeige Profil-Setup als normale Seite (nicht wegslidbar)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileSetupPage(
                firestoreService: _firestoreService,
                onProfileComplete: _onProfileComplete,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ===== Loading Screen =====
    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: const Color(0xFF12100E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: const Color(0xFFFFD700)),
              SizedBox(height: 16),
              Text(
                'SYSTEM BOOT... 🍺',
                style: TextStyle(
                  color: const Color(0xFFFFD700),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ===== Profil-Setup als Modal anzeigen wenn nötig =====
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showProfileSetupIfNeeded();
    });

    // ===== Pages dynamisch basierend auf Login-Status =====
    final List<Widget> pages;
    if (widget.isLoggedIn) {
      // Eingeloggt: Home, Bier, Profile, Einstellungen
      pages = [
        const HomePage(),
        const ConsumptionDiaryPage(), // Konsum-Tagebuch
        const StatistikPage(),
        const ProfilePage(),
        const SettingsPage(),
      ];
    } else if (widget.isGuestMode) {
      // Gast-Modus: Home, Bier (eingeschränkt), Stats (eingeschränkt), Profile, Einstellungen
      pages = [
        const HomePage(),
        _buildGuestBeerPlaceholder(),
        _buildGuestStatsPlaceholder(),
        const ProfilePage(),
        const SettingsPage(),
      ];
    } else {
      // Nicht eingeloggt: Home, Bier (Login-Platzhalter), Profile, Einstellungen
      pages = [
        const HomePage(),
        _buildBeerLoginPlaceholder(),
        const SizedBox(), // Placeholder for Stats
        const ProfilePage(),
        const SettingsPage(),
      ];
    }

    void onItemTapped(int index) {
      if (!widget.isLoggedIn && !widget.isGuestMode) {
        // Nicht eingeloggt und nicht Gast: Index 0=Home, 1=Bier(Login), 2=Stats, 3=Profile
        if (index == 1 || index == 2) {
          setState(() => _selectedIndex = 1); // Bier-Tab aktiv lassen
          // Hinweis/Login öffnen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomLoginPage()),
          );
          return;
        }
      } else if (widget.isGuestMode && (index == 1 || index == 2)) {
        // Gast-Modus: Zeige Hinweis dass Login erforderlich für volle Funktion
        setState(() => _selectedIndex = index);
        return;
      }

      setState(() {
        _selectedIndex = index;
      });
    }

    // Bottom bar soll nicht mehr transparent sein, damit der Add-Button nicht verdeckt wird.
    return Scaffold(
      extendBody: false,
      appBar: AppBar(
        title: const Text(
          "FEIERABEND BIERCHEN",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0xFFFFA000), // Dunkles Amber
                Color(0xFFFFC107), // Gold
              ],
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: BubblePainter(
                  bubbles: _bubbles,
                  animationValue: _controller.value,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 1.5,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF12100E), // Deep Beer Black
              Color(0xFF251D18), // Dark Roasted Malt
            ],
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: pages[_selectedIndex],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12100E), // volle Deckkraft
          border: Border(
            top: BorderSide(color: const Color(0xFF8D6E63).withOpacity(0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF12100E),
          elevation: 0,
          selectedItemColor: const Color(0xFFFFD700),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: AppLocalizations.of(context).t('home'),
            ),
            // Bierseite immer anzeigen
            BottomNavigationBarItem(
              icon: const Icon(Icons.local_drink),
              label: AppLocalizations.of(context).t('beer'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart),
              label: AppLocalizations.of(context).t('stats'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle),
              label: AppLocalizations.of(context).t('account'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: AppLocalizations.of(context).t('settings'),
            ),
          ],
        ),
      ),
    );
  }

  // Platzhalter wenn nicht eingeloggt
  Widget _buildBeerLoginPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_drink, size: 64, color: const Color(0xFFFFD700)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).t('access_denied'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).t('auth_required'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomLoginPage(),
                ),
              );
            },
            icon: const Icon(Icons.login),
            label: Text(AppLocalizations.of(context).t('login_button')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700).withOpacity(0.1),
              foregroundColor: const Color(0xFFFFD700),
              side: const BorderSide(color: Color(0xFF8D6E63)),
            ),
          ),
        ],
      ),
    );
  }

  // Platzhalter für Gast-Modus (Bier)
  Widget _buildGuestBeerPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_drink, size: 64, color: const Color(0xFFFFD700)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).t('guest_mode'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).t('guest_mode_description'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomLoginPage(),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: Text(AppLocalizations.of(context).t('register_button')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700).withOpacity(0.1),
              foregroundColor: const Color(0xFFFFD700),
              side: const BorderSide(color: Color(0xFF8D6E63)),
            ),
          ),
        ],
      ),
    );
  }

  // Platzhalter für Gast-Modus (Stats)
  Widget _buildGuestStatsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: const Color(0xFFFFD700)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).t('guest_mode'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Statistiken sind nur mit Account verfügbar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomLoginPage(),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: Text(AppLocalizations.of(context).t('register_button')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700).withOpacity(0.1),
              foregroundColor: const Color(0xFFFFD700),
              side: const BorderSide(color: Color(0xFF8D6E63)),
            ),
          ),
        ],
      ),
    );
  }
}

// Bubble-Klasse für Animation
class Bubble {
  final double x;
  final double y;
  final double size;
  final double speed;

  Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

// BubblePainter für CustomPainter
class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double animationValue;

  BubblePainter({required this.bubbles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (var bubble in bubbles) {
      // Berechne Y-Position basierend auf Animation (Looping)
      // Wir addieren animationValue * speed zur ursprünglichen Y und nehmen Modulo 1
      // Da wir wollen, dass sie nach OBEN steigen, subtrahieren wir.
      double currentY = (bubble.y - (animationValue * bubble.speed)) % 1.0;
      if (currentY < 0) currentY += 1.0;

      // Zeichne Blase
      canvas.drawCircle(
        Offset(bubble.x * size.width, currentY * size.height),
        bubble.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
