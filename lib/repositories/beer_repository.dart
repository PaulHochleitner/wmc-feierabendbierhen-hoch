import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/consumed_beer.dart';
import '../core/constants/app_constants.dart';

/// Repository für Bier-Datenzugriff
class BeerRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  /// Stream aller konsumierten Biere des aktuellen Users
  Stream<List<ConsumedBeer>> getBeersStream() {
    if (userId == null) {
      return Stream.value([]);
    }

    return _db
        .collection(AppConstants.collectionUsers)
        .doc(userId)
        .collection(AppConstants.subcollectionUserBeers)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConsumedBeer.fromFirestore(doc))
          .toList();
    });
  }

  /// Lädt alle konsumierten Biere des aktuellen Users
  Future<List<ConsumedBeer>> getAllBeers() async {
    if (userId == null) return [];

    try {
      final snapshot = await _db
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .collection(AppConstants.subcollectionUserBeers)
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ConsumedBeer.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fügt ein neues Bier hinzu
  Future<void> addBeer(ConsumedBeer beer) async {
    if (userId == null) {
      throw Exception('Kein User eingeloggt');
    }

    try {
      await _db
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .collection(AppConstants.subcollectionUserBeers)
          .add(beer.toFirestore());
    } catch (e) {
      throw Exception('Fehler beim Hinzufügen des Biers: $e');
    }
  }

  /// Aktualisiert ein bestehendes Bier
  Future<void> updateBeer(ConsumedBeer beer) async {
    if (userId == null) {
      throw Exception('Kein User eingeloggt');
    }

    if (beer.id == null) {
      throw Exception('Bier-ID fehlt');
    }

    try {
      await _db
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .collection(AppConstants.subcollectionUserBeers)
          .doc(beer.id)
          .update(beer.toFirestore());
    } catch (e) {
      throw Exception('Fehler beim Aktualisieren des Biers: $e');
    }
  }

  /// Löscht ein Bier
  Future<void> deleteBeer(String beerId) async {
    if (userId == null) {
      throw Exception('Kein User eingeloggt');
    }

    try {
      await _db
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .collection(AppConstants.subcollectionUserBeers)
          .doc(beerId)
          .delete();
    } catch (e) {
      throw Exception('Fehler beim Löschen des Biers: $e');
    }
  }
}
