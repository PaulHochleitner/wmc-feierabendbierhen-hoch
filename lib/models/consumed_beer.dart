import 'package:cloud_firestore/cloud_firestore.dart';

/// Model für ein konsumiertes Bier
class ConsumedBeer {
  final String? id;
  final String name;
  final String country;
  final double percentage;
  final int rating;
  final DateTime date;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  ConsumedBeer({
    this.id,
    required this.name,
    required this.country,
    required this.percentage,
    required this.rating,
    required this.date,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  /// Konvertiert das Model zu einer Map für Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'country': country,
      'percentage': percentage,
      'rating': rating,
      'date': Timestamp.fromDate(date),
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  /// Erstellt ein ConsumedBeer aus einem Firestore-Dokument
  factory ConsumedBeer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConsumedBeer(
      id: doc.id,
      name: data['name'] ?? '',
      country: data['country'] ?? '',
      percentage: (data['percentage'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0).toInt(),
      date: (data['date'] as Timestamp).toDate(),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      locationName: data['locationName'],
    );
  }

  /// Erstellt eine Kopie mit geänderten Werten
  ConsumedBeer copyWith({
    String? id,
    String? name,
    String? country,
    double? percentage,
    int? rating,
    DateTime? date,
    double? latitude,
    double? longitude,
    String? locationName,
  }) {
    return ConsumedBeer(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      percentage: percentage ?? this.percentage,
      rating: rating ?? this.rating,
      date: date ?? this.date,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
    );
  }

  /// Prüft ob ein Standort gesetzt ist
  bool hasLocation() {
    return latitude != null && longitude != null;
  }

  /// Gibt das Länder-Emoji zurück (erste 2 Unicode-Zeichen des country-Strings)
  String getCountryEmoji() {
    if (country.isEmpty) return '';
    // Emojis sind Unicode-Zeichen, die mehr als 1 Byte benötigen
    // Wir nehmen die ersten 2 Zeichen (für Flaggen-Emojis wie 🇦🇹)
    final runes = country.runes.toList();
    if (runes.length >= 2) {
      return String.fromCharCodes(runes.sublist(0, 2));
    }
    return country.substring(0, 1);
  }

  /// Gibt den Länder-Namen zurück (ohne Emoji)
  String getCountryName() {
    if (country.isEmpty) return '';
    // Entferne die ersten 2 Unicode-Zeichen (Emoji) und das Leerzeichen
    final runes = country.runes.toList();
    if (runes.length > 2) {
      // Überspringe Emoji (2 Zeichen) + Leerzeichen (1 Zeichen) = 3 Zeichen
      return String.fromCharCodes(runes.sublist(3));
    }
    return country;
  }
}
