// lib/services/beer_firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class BeerFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  Future<void> createUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(userId).set(profile.toFirestore());
  }

  Future<UserProfile?> getUserProfile() async {
    if (userId == null) return null;
    DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(userId).update(profile.toFirestore());
  }
}