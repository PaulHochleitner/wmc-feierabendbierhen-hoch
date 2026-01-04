import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:feierabendbierchen_flutter/pages/profile/login_page.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
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
    await FirebaseAuth.instance.signOut();
    setState(() {
      _userProfile = null;
    });
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UserProfileSetupPage(
        firestoreService: _firestoreService,
        onProfileComplete: _loadProfile,
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

    // Nicht eingeloggt - Login-Seite anzeigen
    if (user == null) {
      return SingleChildScrollView(
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
                  MaterialPageRoute(builder: (context) => const LoginPage()),
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
      );
    }

    // Eingeloggt aber kein Profil
    if (_userProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: Color(0xFFFFD700)),
            const SizedBox(height: 16),
            Text(
              'KEIN PROFIL GEFUNDEN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bitte erstelle ein Profil.',
              style: TextStyle(color: const Color(0xFFD7CCC8)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _editProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700).withOpacity(0.1),
                foregroundColor: const Color(0xFFFFD700),
                side: const BorderSide(color: Color(0xFF8D6E63)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text("PROFIL ERSTELLEN"),
            ),
          ],
        ),
      );
    }

    // Eingeloggt mit Profil - Profil anzeigen
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
        );
      }
    );
  }
}
