// lib/pages/main_navigation.dart (umbenennen von MyHomePage)
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:feierabendbierchen_flutter/pages/home/home_page.dart';
import 'package:feierabendbierchen_flutter/pages/beer/beer_page.dart';
import 'package:feierabendbierchen_flutter/pages/statistik/statisitk_page.dart';
import 'package:feierabendbierchen_flutter/pages/profile/profile_page.dart';
import 'package:feierabendbierchen_flutter/pages/profile/login_page.dart';
import 'package:feierabendbierchen_flutter/pages/profile/user_profile_setup_page.dart';

class MyHomePage extends StatefulWidget {
  final bool isLoggedIn;

  const MyHomePage({super.key, required this.isLoggedIn});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
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
      _bubbles.add(Bubble(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 4,
        speed: 0.3 + _random.nextDouble() * 0.7,
      ));
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
      // Zeige Profil-Setup als Modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => UserProfileSetupPage(
          firestoreService: _firestoreService,
          onProfileComplete: _onProfileComplete,
        ),
      );
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
              CircularProgressIndicator(
                color: const Color(0xFFFFD700),
              ),
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
      // Eingeloggt: Home, Bier, Profile
      pages = [
        const HomePage(),
        const BeerPage(), // Bier-Seite immer anzeigen, unabhängig vom Profil
        const StatistikPage(),
        const ProfilePage(),
      ];
    } else {
      // Nicht eingeloggt: Home, Bier (Login-Platzhalter), Profile
      pages = [
        const HomePage(),
        _buildBeerLoginPlaceholder(),
        const SizedBox(), // Placeholder for Stats
        const ProfilePage(),
      ];
    }

    void onItemTapped(int index) {
      if (!widget.isLoggedIn) {
        // Nicht eingeloggt: Index 0=Home, 1=Bier(Login), 2=Stats, 3=Profile
        if (index == 1 || index == 2) {
          setState(() => _selectedIndex = 1); // Bier-Tab aktiv lassen
          // Hinweis/Login öffnen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
          return;
        }
      }
      
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      extendBody: true, // Important for transparent bottom bar
      appBar: AppBar(
        title: const Text("FEIERABEND BIERCHEN", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12100E).withOpacity(0.95),
          border: Border(top: BorderSide(color: const Color(0xFF8D6E63).withOpacity(0.3))),
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFFFD700),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: "HOME"),
            // Bierseite immer anzeigen
            const BottomNavigationBarItem(
              icon: Icon(Icons.local_drink),
              label: "BIER",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: "STATS",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: "ACCOUNT",
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
          Icon(
            Icons.local_drink,
            size: 64,
            color: const Color(0xFFFFD700),
          ),
          const SizedBox(height: 16),
          Text(
            'ZUGRIFF VERWEIGERT 🍺',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Authentifizierung erforderlich für Bier-Tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('LOGIN PROTOKOLL'),
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
