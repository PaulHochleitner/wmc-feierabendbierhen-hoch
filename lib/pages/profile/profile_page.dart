import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:feierabendbierchen_flutter/pages/profile/custom_login_page.dart';
import 'package:feierabendbierchen_flutter/services/auth_service.dart';
import 'package:feierabendbierchen_flutter/pages/profile/user_profile_setup_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final BeerFirestoreService _firestoreService = BeerFirestoreService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isGuestMode = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      // Prüfe zuerst ob Gast-Modus aktiv ist
      final isGuest = await AuthService.isGuestMode();
      final user = FirebaseAuth.instance.currentUser;
      
      if (mounted) {
        setState(() {
          _isGuestMode = isGuest;
        });
      }
      
      if (isGuest) {
        // Gast-Modus - kein Profil laden
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      if (user != null) {
        final profile = await _firestoreService.getUserProfile();
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await AuthService.logout();
    setState(() {
      _userProfile = null;
    });
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileSetupPage(
          firestoreService: _firestoreService,
          onProfileComplete: _loadProfile,
          existingProfile: _userProfile, // Vorhandenes Profil übergeben
        ),
      ),
    );
  }

  Widget _buildAvatar(UserProfile profile, {double radius = 50}) {
    if (profile.hasImage()) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(profile.imageUrl!),
        ),
      );
    } else {
      // Flutter-only Avatar mit Initialen
      final initials = profile.name.isNotEmpty
          ? profile.name.substring(0, 1).toUpperCase()
          : '?';
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF1F1B16),
          child: Text(
            initials,
            style: TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
              shadows: [
                Shadow(
                  blurRadius: 5,
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildFuturisticCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1917),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8D6E63).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFFD700), size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF8D6E63),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFuturisticCard(Icons.person, 'Identität', profile.name),
        _buildFuturisticCard(Icons.monitor_weight, 'Masse', '${profile.weight.toStringAsFixed(1)} kg'),
        _buildFuturisticCard(Icons.height, 'Größe', '${profile.height.toStringAsFixed(0)} cm'),
        _buildFuturisticCard(
          profile.gender == 'male' ? Icons.male : Icons.female,
          'Biologie',
          profile.gender == 'male' ? 'Männlich' : 'Weiblich',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: const Color(0xFFFFD700)),
      );
    }

    // Gast-Modus - spezieller Gast-Screen
    if (_isGuestMode) {
      return _buildGuestScreen();
    }

    // Nicht eingeloggt - Login-Seite anzeigen
    if (user == null) {
      return _buildLoginScreen();
    }

    // Eingeloggt aber kein Profil - zeige Email und Option zum Profil erstellen
    if (_userProfile == null) {
      // Bottom Navigation Bar Höhe (ca. 56-80px)
      final bottomPadding = MediaQuery.of(context).padding.bottom + 80;
      
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Avatar mit Email
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_circle,
                        size: 80,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      user.email ?? 'Keine Email',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Eingeloggt',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1917),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF8D6E63).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFFFFD700),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Profil nicht vollständig',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gib deine Daten ein, um personalisierte Statistiken zu erhalten. Ohne Profil-Daten kannst du die App nutzen, aber keine personalisierten Statistiken sehen.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Profil erstellen Button
              ElevatedButton(
                onPressed: _editProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  'PROFIL ERSTELLEN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Optional: Später Button
              TextButton(
                onPressed: () {
                  // Nichts tun - User kann später Profil erstellen
                },
                child: Text(
                  'Später',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Eingeloggt mit Profil - Profil anzeigen
    // Bottom Navigation Bar Höhe (ca. 56-80px)
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                  // Header mit Avatar und Infos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _editProfile,
                          child: Stack(
                            children: [
                              _buildAvatar(_userProfile!, radius: 40),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userProfile!.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFD4AF37),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Profil-Informationen
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildProfileInfo(_userProfile!),
                  ),
                  
                  const Spacer(), // Drückt den Button nach unten
                  
                  // Abmelden Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('SYSTEM DISCONNECT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shadowColor: Colors.redAccent.withOpacity(0.5),
                          elevation: 10,
                        ),
                      ),
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildGuestScreen() {
    // Bottom Navigation Bar Höhe (ca. 56-80px)
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, bottomPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Gast Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 80,
                  color: Color(0xFFFFD700),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Gast Status
            Text(
              'ALS GAST',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Text
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1917),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF8D6E63).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Im Gast-Modus werden deine Daten nicht gespeichert.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Erstelle einen Account, um deine Biere zu tracken und Statistiken zu sehen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Account erstellen Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomLoginPage(isRegisterMode: true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: const Text(
                'ACCOUNT ERSTELLEN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Oder Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[700])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ODER',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[700])),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Anmelden Button
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomLoginPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD700),
                side: const BorderSide(color: Color(0xFFFFD700), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ANMELDEN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Bier Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1917),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_drink,
                  size: 64,
                  color: Color(0xFFFFD700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginScreen() {
    // Bottom Navigation Bar Höhe (ca. 56-80px)
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "IDENTIFIZIERUNG ERFORDERLICH 🍺",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Initialisiere Login-Protokoll für personalisierte Daten.",
              style: TextStyle(fontSize: 16, color: const Color(0xFFD7CCC8)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomLoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700).withOpacity(0.1),
                foregroundColor: const Color(0xFFFFD700),
                side: const BorderSide(color: Color(0xFF8D6E63)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text("Login"),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 400,
              height: 400,
              child: Image(
                image: AssetImage('assets/consumed-beer.png'),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
