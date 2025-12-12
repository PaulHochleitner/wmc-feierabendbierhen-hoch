import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/brewery.dart';

class BreweryService {
  BreweryService({http.Client? client}) : _client = client ?? http.Client();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final http.Client _client;

  static const _apiBaseUrl = 'https://api.openbrewerydb.org/v1/breweries';
  static const _seedMetadataCollection = 'metadata';
  static const _seedMetadataDoc = 'brewery_seed';

  Future<List<Brewery>> getBreweries() async {
    await _seedBreweriesIfNeeded();

    final snapshot = await _db
        .collection('breweries')
        .orderBy('name')
        .get(const GetOptions(source: Source.serverAndCache));

    return snapshot.docs.map(Brewery.fromFirestore).toList();
  }

  Future<void> _seedBreweriesIfNeeded() async {
    final metaRef =
        _db.collection(_seedMetadataCollection).doc(_seedMetadataDoc);
    final metaSnap = await metaRef.get(const GetOptions(source: Source.server));

    final alreadySeeded = metaSnap.exists &&
        (metaSnap.data()?['seeded'] == true || metaSnap.data()?['count'] != null);

    if (alreadySeeded) return;

    final breweries = await _fetchFromApi(limit: 50);
    if (breweries.isEmpty) return;

    final batch = _db.batch();
    for (final brewery in breweries) {
      final docRef = _db.collection('breweries').doc(brewery.id);
      batch.set(docRef, brewery.toFirestore(), SetOptions(merge: true));
    }

    batch.set(metaRef, {
      'seeded': true,
      'count': breweries.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<List<Brewery>> _fetchFromApi({int limit = 50}) async {
    final uri = Uri.parse('$_apiBaseUrl?per_page=$limit');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('OpenBreweryDB error: ${response.statusCode}');
    }

    final decoded = json.decode(response.body) as List<dynamic>;
    return decoded
        .map((e) => Brewery.fromApi(e as Map<String, dynamic>))
        .toList();
  }
}

