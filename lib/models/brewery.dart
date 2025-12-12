import 'package:cloud_firestore/cloud_firestore.dart';

class Brewery {
  final String id;
  final String name;
  final String breweryType;
  final String? address1;
  final String? address2;
  final String? address3;
  final String? city;
  final String? stateProvince;
  final String? postalCode;
  final String? country;
  final double? longitude;
  final double? latitude;
  final String? phone;
  final String? websiteUrl;

  Brewery({
    required this.id,
    required this.name,
    required this.breweryType,
    this.address1,
    this.address2,
    this.address3,
    this.city,
    this.stateProvince,
    this.postalCode,
    this.country,
    this.longitude,
    this.latitude,
    this.phone,
    this.websiteUrl,
  });

  factory Brewery.fromApi(Map<String, dynamic> json) {
    double? _toDouble(dynamic value) {
      if (value == null) return null;
      return double.tryParse(value.toString());
    }

    return Brewery(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      breweryType: json['brewery_type'] ?? '',
      address1: json['address_1'],
      address2: json['address_2'],
      address3: json['address_3'],
      city: json['city'],
      stateProvince: json['state_province'],
      postalCode: json['postal_code'],
      country: json['country'],
      longitude: _toDouble(json['longitude']),
      latitude: _toDouble(json['latitude']),
      phone: json['phone'],
      websiteUrl: json['website_url'],
    );
  }

  factory Brewery.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Brewery(
      id: doc.id,
      name: data['name'] ?? '',
      breweryType: data['breweryType'] ?? '',
      address1: data['address1'],
      address2: data['address2'],
      address3: data['address3'],
      city: data['city'],
      stateProvince: data['stateProvince'],
      postalCode: data['postalCode'],
      country: data['country'],
      longitude: (data['longitude'] as num?)?.toDouble(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      phone: data['phone'],
      websiteUrl: data['websiteUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'breweryType': breweryType,
      'address1': address1,
      'address2': address2,
      'address3': address3,
      'city': city,
      'stateProvince': stateProvince,
      'postalCode': postalCode,
      'country': country,
      'longitude': longitude,
      'latitude': latitude,
      'phone': phone,
      'websiteUrl': websiteUrl,
    };
  }
}

