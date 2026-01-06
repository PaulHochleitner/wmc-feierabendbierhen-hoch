// lib/models/user_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String name;
  final double weight; // in kg
  final double height; // in cm
  final String gender; // "male" or "female"
  final String? imageUrl; // Profilbild URL (kann null sein)
  final DateTime? createdAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.weight,
    required this.height,
    required this.gender,
    this.imageUrl,
    this.createdAt,
  });

  // Von Firestore zu Dart Object
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      userId: doc.id,
      name: data['name'] ?? '',
      weight: (data['weight'] ?? 75).toDouble(),
      height: (data['height'] ?? 175).toDouble(),
      gender: data['gender'] ?? 'male',
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Von Dart Object zu Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'weight': weight,
      'height': height,
      'gender': gender,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  // Hilfsmethode: Prüfen ob Profilbild vorhanden
  bool hasImage() {
    return imageUrl != null && imageUrl!.isNotEmpty;
  }
}