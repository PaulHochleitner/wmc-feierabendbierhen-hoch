import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyGuestMode = 'guest_mode';
  static const String _keyUserEmail = 'user_email';

  // Prüft ob es der erste Start ist
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  // Markiert ersten Start als erledigt
  static Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }

  // Setzt Gast-Modus
  static Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGuestMode, isGuest);
  }

  // Prüft ob Gast-Modus aktiv ist
  static Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGuestMode) ?? false;
  }

  // Speichert User-Email für später
  static Future<void> saveUserEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString(_keyUserEmail, email);
    } else {
      await prefs.remove(_keyUserEmail);
    }
  }

  // Gibt gespeicherte Email zurück
  static Future<String?> getSavedUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  // Prüft ob User eingeloggt ist (Firebase Auth)
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  // Logout und Gast-Modus zurücksetzen
  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await setGuestMode(false);
    await saveUserEmail(null);
  }
}

