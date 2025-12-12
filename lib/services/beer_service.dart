import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/beer.dart';

class BeerService {
  BeerService({http.Client? client}) : _client = client ?? http.Client();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final http.Client _client;

  static const _seedMetadataCollection = 'metadata';
  static const _seedMetadataDoc = 'beer_seed';
  static const _rawBase =
      'https://raw.githubusercontent.com/openbeer/at-austria/master';

  static const List<String> _regionFiles = [
    '1--b-burgenland--eastern/beers.txt',
    '1--n-niederoesterreich--eastern/beers.txt',
    '1--w-wien--eastern/beers.txt',
    '2--k-kaernten--southern/beers.txt',
    '2--st-steiermark--southern/beers.txt',
    '3--o-oberoesterreich--western/beers.txt',
    '3--s-salzburg--western/beers.txt',
    '3--t-tirol--western/beers.txt',
    '3--v-vorarlberg--western/beers.txt',
  ];

  Future<List<Beer>> getBeers() async {
    await _seedBeersIfNeeded();

    final snapshot = await _db
        .collection('beers')
        .orderBy('name')
        .get(const GetOptions(source: Source.serverAndCache));

    return snapshot.docs
        .map((doc) => Beer.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<void> _seedBeersIfNeeded() async {
    final metaRef =
        _db.collection(_seedMetadataCollection).doc(_seedMetadataDoc);
    final metaSnap = await metaRef.get(const GetOptions(source: Source.server));

    final alreadySeeded = metaSnap.exists &&
        (metaSnap.data()?['seeded'] == true || metaSnap.data()?['count'] != null);
    if (alreadySeeded) return;

    final beers = await _fetchAllBeers();
    if (beers.isEmpty) return;

    final batch = _db.batch();
    for (final beer in beers) {
      final docRef = _db.collection('beers').doc(beer.id);
      batch.set(docRef, beer.toFirestore(), SetOptions(merge: true));
    }

    batch.set(metaRef, {
      'seeded': true,
      'count': beers.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<List<Beer>> _fetchAllBeers() async {
    final List<Beer> beers = [];
    for (final path in _regionFiles) {
      final uri = Uri.parse('$_rawBase/$path');
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        continue; // skip missing regions silently
      }
      beers.addAll(_parseBeers(utf8.decode(response.bodyBytes), path));
    }
    return beers;
  }

  List<Beer> _parseBeers(String content, String regionPath) {
    final List<Beer> beers = [];
    final region = regionPath.split('/').first;
    String currentBrewery = 'Unbekannte Brauerei';

    final lines = const LineSplitter().convert(content);
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('#') || trimmed.startsWith('===') || trimmed.startsWith('___')) {
        continue;
      }
      if (trimmed.startsWith('- ')) {
        currentBrewery = trimmed.substring(2).trim();
        continue;
      }

      final beerName = _extractName(trimmed);
      if (beerName.isEmpty) continue;

      final abv = _extractAbv(trimmed);
      final style = _extractStyle(trimmed);
      final id = _makeId(region, currentBrewery, beerName);

      beers.add(Beer(
        id: id,
        name: beerName,
        brewery: currentBrewery,
        region: region,
        abv: abv,
        style: style,
        notes: trimmed,
      ));
    }
    return beers;
  }

  String _extractName(String line) {
    // take text before first comma or whole line
    final idx = line.indexOf(',');
    final name = (idx == -1 ? line : line.substring(0, idx)).trim();
    return name;
  }

  double? _extractAbv(String line) {
    final match = RegExp(r'(\\d+(?:\\.\\d+)?)%').firstMatch(line);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  String? _extractStyle(String line) {
    final parts = line.split(',');
    if (parts.length < 2) return null;
    // skip first (name) and join the rest
    final rest = parts.skip(1).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (rest.isEmpty) return null;
    // remove abv tokens from style string
    final cleaned = rest.join(', ');
    final style = cleaned.replaceAll(RegExp(r'\\d+(?:\\.\\d+)?%'), '').trim();
    return style.isEmpty ? null : style;
  }

  String _makeId(String region, String brewery, String name) {
    final raw = '$region-$brewery-$name'.toLowerCase();
    return raw.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp('-+'), '-');
  }
}

