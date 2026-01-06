// lib/models/beer.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Beer {
  final String id;
  final String name;
  final double? abv; // Alkoholgehalt in %
  final double? og; // Stammwürze in °
  final String breweryId;
  final String breweryName;
  final String region;
  final String country;
  final List<String> tags;

  Beer({
    required this.id,
    required this.name,
    this.abv,
    this.og,
    required this.breweryId,
    required this.breweryName,
    required this.region,
    required this.country,
    required this.tags,
  });

  // Von Firestore zu Dart Object
  factory Beer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Beer(
      id: doc.id,
      name: data['name'] ?? '',
      abv: data['abv'] != null ? (data['abv'] as num).toDouble() : null,
      og: data['og'] != null ? (data['og'] as num).toDouble() : null,
      breweryId: data['breweryId'] ?? '',
      breweryName: data['breweryName'] ?? 'Unknown',
      region: data['region'] ?? '',
      country: data['country'] ?? 'Austria',
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  // Von Dart Object zu Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'abv': abv,
      'og': og,
      'breweryId': breweryId,
      'breweryName': breweryName,
      'region': region,
      'country': country,
      'tags': tags,
    };
  }
}

