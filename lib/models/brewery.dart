// lib/models/brewery.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Brewery {
  final String id;
  final String name;
  final String? founded;
  final String location;
  final String region;
  final String country;

  Brewery({
    required this.id,
    required this.name,
    this.founded,
    required this.location,
    required this.region,
    required this.country,
  });

  // Von Firestore zu Dart Object
  factory Brewery.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Brewery(
      id: doc.id,
      name: data['name'] ?? '',
      founded: data['founded'],
      location: data['location'] ?? '',
      region: data['region'] ?? '',
      country: data['country'] ?? 'Austria',
    );
  }

  // Von Dart Object zu Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'founded': founded,
      'location': location,
      'region': region,
      'country': country,
    };
  }
}

