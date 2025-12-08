// lib/pages/main_navigation.dart (umbenennen von MyHomePage)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:feierabendbierchen_flutter/pages/home/home_page.dart';
import 'package:feierabendbierchen_flutter/pages/beer/beer_page.dart';
import 'package:feierabendbierchen_flutter/pages/profile/profile_page.dart';
import 'package:feierabendbierchen_flutter/pages/profile/user_profile_setup_page.dart';

class MyHomePage extends StatefulWidget {
  final bool isLoggedIn;

  const MyHomePage({super.key, required this.isLoggedIn});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  bool _shouldNavigateToBeer = false; // Flag für Navigation zur Bierseite nach Profil-Setup

  // ===== NEU: Profil-Verwaltung =====
  final BeerFirestoreService _firestoreService = BeerFirestoreService();
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;
  bool _needsProfileSetup = false;

  @override
  void initState() {
    super.initState();
    // ===== NEU: Profil beim Start laden =====
    if (widget.isLoggedIn) {
      _checkUserProfile();
    } else {
      setState(() => _isLoadingProfile = false);
    }
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
    _checkUserProfile().then((_) {
      // Wenn User auf Bier geklickt hat, zur Bierseite navigieren
      if (_shouldNavigateToBeer && _userProfile != null) {
        setState(() {
          _selectedIndex = 1; // Bierseite ist Index 1 wenn eingeloggt
        });
        _shouldNavigateToBeer = false;
      }
    });
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: 16),
              Text(
                'Profil wird geladen... 🍺',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
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
        _userProfile != null 
            ? const BeerPage() 
            : _buildBeerPagePlaceholder(),
        const ProfilePage(),
      ];
    } else {
      // Nicht eingeloggt: Home, Profile
      pages = [
        const HomePage(),
        const ProfilePage(),
      ];
    }

    void onItemTapped(int index) {
      if (widget.isLoggedIn) {
        // Eingeloggt: Index 0=Home, 1=Bier, 2=Profile
        if (index == 1 && _userProfile == null) {
          // Wenn auf Bier geklickt wird ohne Profil, zeige Profil-Setup
          _shouldNavigateToBeer = true; // Flag setzen für Navigation nach Setup
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => UserProfileSetupPage(
              firestoreService: _firestoreService,
              onProfileComplete: _onProfileComplete,
            ),
          );
          return;
        }
      } else {
        // Nicht eingeloggt: Index 0=Home, 1=Profile
        // Index bleibt gleich
      }
      
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("FeierabendBierchen"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          // Bierseite immer anzeigen wenn eingeloggt
          if (widget.isLoggedIn)
            const BottomNavigationBarItem(
              icon: Icon(Icons.local_drink),
              label: "Bierchen",
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: "Account",
          ),
        ],
      ),
    );
  }

  // Platzhalter für Bierseite wenn kein Profil existiert
  Widget _buildBeerPagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_drink,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 16),
          Text(
            'Profil erforderlich 🍺',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bitte vervollständige dein Profil, um die Bierseite zu nutzen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => UserProfileSetupPage(
                  firestoreService: _firestoreService,
                  onProfileComplete: _onProfileComplete,
                ),
              );
            },
            icon: Icon(Icons.person_add),
            label: Text('Profil einrichten'),
          ),
        ],
      ),
    );
  }
}
