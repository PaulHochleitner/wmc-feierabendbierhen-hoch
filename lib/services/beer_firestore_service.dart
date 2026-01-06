// lib/services/beer_firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class BeerFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  /// Speichert User-Daten (height, weight, gender) in Firestore
  ///
  /// Collection: "users"
  /// Document ID: User UID (aus Firebase Auth)
  /// Pfad: users/{userUID}
  ///
  /// Felder:
  /// - height (number) - Größe in cm
  /// - weight (number) - Gewicht in kg
  /// - gender (string) - "male", "female" oder "other"
  ///
  /// Wirft eine Exception bei Fehlern (z.B. kein User eingeloggt, Firestore Fehler)
  Future<void> saveUserData({
    required double height,
    required double weight,
    required String gender,
  }) async {
    // 1. Prüfe ob User eingeloggt ist
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Kein User eingeloggt. Bitte zuerst anmelden.');
    }

    final userUID = currentUser.uid;
    if (userUID.isEmpty) {
      throw Exception('User UID ist leer.');
    }

    // 2. Validierung der Eingabedaten
    if (height <= 0 || height > 300) {
      throw Exception(
        'Ungültige Größe. Bitte einen Wert zwischen 1 und 300 cm eingeben.',
      );
    }
    if (weight <= 0 || weight > 500) {
      throw Exception(
        'Ungültiges Gewicht. Bitte einen Wert zwischen 1 und 500 kg eingeben.',
      );
    }
    if (gender != 'male' && gender != 'female' && gender != 'other') {
      throw Exception(
        'Ungültiges Geschlecht. Bitte "male", "female" oder "other" wählen.',
      );
    }

    try {
      // 3. Erstelle/Update Dokument in Firestore
      // Collection: "users", Document ID: userUID
      await _db.collection('users').doc(userUID).set(
        {
          'height': height,
          'weight': weight,
          'gender': gender,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ); // merge: true = bestehende Felder bleiben erhalten
    } on FirebaseException catch (e) {
      // Firestore-spezifische Fehler
      throw Exception('Firestore Fehler: ${e.message}');
    } catch (e) {
      // Allgemeine Fehler
      throw Exception('Fehler beim Speichern der User-Daten: $e');
    }
  }

  /// Speichert vollständiges User-Profil (inkl. name, imageUrl)
  Future<void> createUserProfile(UserProfile profile) async {
    if (userId == null) {
      throw Exception('Kein User eingeloggt. Bitte zuerst anmelden.');
    }

    try {
      await _db
          .collection('users')
          .doc(userId)
          .set(
            profile.toFirestore(),
            SetOptions(
              merge: true,
            ), // merge: true = bestehende Felder bleiben erhalten
          );
    } on FirebaseException catch (e) {
      throw Exception(
        'Firestore Fehler beim Speichern des Profils: ${e.message}',
      );
    } catch (e) {
      throw Exception('Fehler beim Speichern des Profils: $e');
    }
  }

  /// Lädt User-Profil aus Firestore
  Future<UserProfile?> getUserProfile() async {
    if (userId == null) return null;
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } on FirebaseException catch (e) {
      // Firestore Fehler (z.B. Permission Denied)
      debugPrint('Firestore Fehler beim Laden des Profils: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Fehler beim Laden des Profils: $e');
      return null;
    }
  }

  /// Aktualisiert User-Profil in Firestore
  Future<void> updateUserProfile(UserProfile profile) async {
    if (userId == null) {
      throw Exception('Kein User eingeloggt. Bitte zuerst anmelden.');
    }

    try {
      await _db.collection('users').doc(userId).update(profile.toFirestore());
    } on FirebaseException catch (e) {
      throw Exception(
        'Firestore Fehler beim Aktualisieren des Profils: ${e.message}',
      );
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren des Profils: $e');
    }
  }

  /// Setzt das Profilbild URL Feld in Firestore: users/{uid}.imageUrl
  Future<void> setUserImageUrl(String imageUrl) async {
    if (userId == null) {
      throw Exception('Kein User eingeloggt. Bitte zuerst anmelden.');
    }
    try {
      await _db.collection('users').doc(userId).set({
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Firestore Fehler beim Setzen des Bildes: ${e.message}');
    } catch (e) {
      throw Exception('Fehler beim Setzen des Bildes: $e');
    }
  }
}
