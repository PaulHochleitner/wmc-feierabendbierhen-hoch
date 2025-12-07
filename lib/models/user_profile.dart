// lib/models/user_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String name;
  final double weight; // in kg
  final String gender; // "male" or "female"
  final String? imageUrl; // Profilbild URL (kann null sein)
  final DateTime? createdAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.weight,
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
      'gender': gender,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  // Hilfsmethode: Avatar URL bekommen (mit Fallback)
  String getAvatarUrl() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    
    // Default Avatar wenn kein Bild hochgeladen
    String bgColor = gender == 'male' ? '0D47A1' : 'E91E63';
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=$bgColor&color=fff&size=512';
  }
}