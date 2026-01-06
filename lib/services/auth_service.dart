import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';

class AuthService {

  /// Prüft ob es der erste Start ist
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyFirstLaunch) ?? true;
  }

  /// Markiert ersten Start als erledigt
  static Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyFirstLaunch, false);
  }

  /// Setzt Gast-Modus
  static Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyGuestMode, isGuest);
  }

  /// Prüft ob Gast-Modus aktiv ist
  static Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyGuestMode) ?? false;
  }

  /// Speichert User-Email für später
  static Future<void> saveUserEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString(AppConstants.keyUserEmail, email);
    } else {
      await prefs.remove(AppConstants.keyUserEmail);
    }
  }

  /// Gibt gespeicherte Email zurück
  static Future<String?> getSavedUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyUserEmail);
  }

  /// Prüft ob User eingeloggt ist (Firebase Auth)
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// Logout und Gast-Modus zurücksetzen
  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await setGuestMode(false);
    await saveUserEmail(null);
  }
}

