import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:feierabendbierchen_flutter/pages/profile/login_page.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _firestoreService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _userProfile = null;
    });
  }

  Widget _buildAvatar(UserProfile profile) {
    if (profile.hasImage()) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(profile.imageUrl!),
      );
    } else {
      // Flutter-only Avatar mit Initialen
      final initials = profile.name.isNotEmpty
          ? profile.name.substring(0, 1).toUpperCase()
          : '?';
      return CircleAvatar(
        radius: 60,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  Widget _buildProfileInfo(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Gewicht
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.monitor_weight,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gewicht',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${profile.weight.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Geschlecht
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  profile.gender == 'male' ? Icons.male : Icons.female,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Geschlecht',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        profile.gender == 'male' ? 'Männlich' : 'Weiblich',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Nicht eingeloggt - Login-Seite anzeigen
    if (user == null) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ES GEHT NOCH PERSÖNLICHER 🍺",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Für ein personalisiertes App-Erlebnis, melde dich an oder log dich ein.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Profil wird geladen...'),
          ],
        ),
      );
    }

    // Eingeloggt mit Profil - Profil anzeigen
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Avatar
          _buildAvatar(_userProfile!),
          const SizedBox(height: 16),
          // Name als Titel
          Text(
            _userProfile!.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          // Profil-Informationen
          _buildProfileInfo(_userProfile!),
          const SizedBox(height: 32),
          // Abmelden Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Abmelden'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
