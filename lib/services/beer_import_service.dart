// lib/services/beer_import_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/brewery.dart';
import '../models/beer.dart';

class BeerImportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // GitHub Raw Data URLs - Österreichische Bundesländer
  static const Map<String, Map<String, String>> dataSources = {
    'wien': {
      'breweries': 'https://raw.githubusercontent.com/openbeer/at-austria/master/1--w-wien--eastern/breweries.txt',
      'beers': 'https://raw.githubusercontent.com/openbeer/at-austria/master/1--w-wien--eastern/beers.txt',
    },
    'niederoesterreich': {
      'breweries': 'https://raw.githubusercontent.com/openbeer/at-austria/master/1--n-niederoesterreich--eastern/breweries.txt',
      'beers': 'https://raw.githubusercontent.com/openbeer/at-austria/master/1--n-niederoesterreich--eastern/beers.txt',
    },
    'steiermark': {
      'breweries': 'https://raw.githubusercontent.com/openbeer/at-austria/master/2--st-steiermark--southern/breweries.txt',
      'beers': 'https://raw.githubusercontent.com/openbeer/at-austria/master/2--st-steiermark--southern/beers.txt',
    },
    'oberoesterreich': {
      'breweries': 'https://raw.githubusercontent.com/openbeer/at-austria/master/3--o-oberoesterreich--western/breweries.txt',
      'beers': 'https://raw.githubusercontent.com/openbeer/at-austria/master/3--o-oberoesterreich--western/beers.txt',
    },
    'salzburg': {
      'breweries': 'https://raw.githubusercontent.com/openbeer/at-austria/master/3--s-salzburg--western/breweries.txt',
      'beers': 'https://raw.githubusercontent.com/openbeer/at-austria/master/3--s-salzburg--western/beers.txt',
    },
    'tirol': {
      'breweries': 'https://raw.githubusercontent.com/openbeer/at-austria/master/3--t-tirol--western/breweries.txt',
      'beers': 'https://raw.githubusercontent.com/openbeer/at-austria/master/3--t-tirol--western/beers.txt',
    },
    'kaernten': {
      'breweries': 'https://raw.githubusercontent.com/openbeer/at-austria/master/2--k-kaernten--southern/breweries.txt',
      'beers': 'https://raw.githubusercontent.com/openbeer/at-austria/master/2--k-kaernten--southern/beers.txt',
    },
    'vorarlberg': {
      'breweries': 'https://raw.githubusercontent.com/openbeer/at-austria/master/3--v-vorarlberg--western/breweries.txt',
      'beers': 'https://raw.githubusercontent.com/openbeer/at-austria/master/3--v-vorarlberg--western/beers.txt',
    },
    'burgenland': {
      'breweries': 'https://raw.githubusercontent.com/openbeer/at-austria/master/1--b-burgenland--eastern/breweries.txt',
      'beers': 'https://raw.githubusercontent.com/openbeer/at-austria/master/1--b-burgenland--eastern/beers.txt',
    },
  };

  /// Prüft, ob die Daten bereits importiert wurden
  Future<bool> isDataImported() async {
    try {
      final snapshot = await _db.collection('beers').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Generiert eine ID aus einem Namen
  String _generateId(String name) {
    return name
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Parsed eine Brauerei-Zeile
  Brewery? _parseBrewery(String line, String region) {
    if (line.trim().isEmpty || line.startsWith('#')) return null;

    final parts = line.split(',').map((p) => p.trim()).toList();
    if (parts.isEmpty) return null;

    final name = parts[0];
    if (name.isEmpty) return null;

    return Brewery(
      id: _generateId(name),
      name: name,
      founded: parts.length > 1 ? parts[1] : null,
      location: parts.length > 2 ? parts.sublist(2).join(', ') : region,
      region: region,
      country: 'Austria',
    );
  }

  /// Bestimmt den Biertyp basierend auf Namen & ABV
  List<String> _determineBeerType(String name, double? abv) {
    final tags = <String>[];
    final nameLower = name.toLowerCase();

    if (nameLower.contains('pils')) tags.add('Pils');
    if (nameLower.contains('weizen') || nameLower.contains('weisse')) {
      tags.add('Weizen');
    }
    if (nameLower.contains('dunkel')) tags.add('Dunkel');
    if (nameLower.contains('hell')) tags.add('Hell');
    if (nameLower.contains('märzen')) tags.add('Märzen');
    if (nameLower.contains('zwickl')) tags.add('Zwickl');
    if (nameLower.contains('bock')) tags.add('Bock');
    if (nameLower.contains('bio')) tags.add('Bio');
    if (nameLower.contains('radler')) tags.add('Radler');

    // ABV-basierte Tags
    if (abv != null && abv < 3.5) tags.add('Leicht');
    if (abv != null && abv >= 7) tags.add('Stark');

    return tags.isEmpty ? ['Lager'] : tags;
  }

  /// Parsed eine Bier-Zeile
  Beer? _parseBeer(String line, Brewery? currentBrewery, String region) {
    if (line.trim().isEmpty || line.startsWith('#') || line.contains('___')) {
      return null;
    }

    // Neue Brauerei beginnt mit "- Brauerei Name"
    if (line.startsWith('-')) {
      return null; // Wird separat behandelt
    }

    final parts = line.split(',').map((p) => p.trim()).toList();
    if (parts.isEmpty) return null;

    final name = parts[0];
    if (name.isEmpty) return null;

    // ABV extrahieren (Alkoholgehalt)
    double? abv;
    if (parts.length > 1) {
      final abvMatch = RegExp(r'(\d+\.?\d*)%').firstMatch(parts[1]);
      if (abvMatch != null) {
        abv = double.tryParse(abvMatch.group(1)!);
      }
    }

    // OG extrahieren (Stammwürze)
    double? og;
    if (parts.length > 2) {
      final ogMatch = RegExp(r'(\d+\.?\d*)°').firstMatch(parts[2]);
      if (ogMatch != null) {
        og = double.tryParse(ogMatch.group(1)!);
      }
    }

    final breweryId = currentBrewery?.id ?? 'unknown';
    final beerId = '$breweryId-${_generateId(name)}';

    return Beer(
      id: beerId,
      name: name,
      abv: abv,
      og: og,
      breweryId: breweryId,
      breweryName: currentBrewery?.name ?? 'Unknown',
      region: region,
      country: 'Austria',
      tags: _determineBeerType(name, abv),
    );
  }

  /// Fetched & parsed Brauereien aus einer URL
  Future<List<Brewery>> _fetchBreweries(String url, String region) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final lines = const LineSplitter().convert(response.body);
      final breweries = <Brewery>[];

      for (final line in lines) {
        final brewery = _parseBrewery(line, region);
        if (brewery != null) {
          breweries.add(brewery);
        }
      }

      return breweries;
    } catch (e) {
      print('⚠️  Fehler beim Laden von $region Brauereien: $e');
      return [];
    }
  }

  /// Fetched & parsed Biere aus einer URL
  Future<List<Beer>> _fetchBeers(
    String url,
    String region,
    Map<String, Brewery> breweriesMap,
  ) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final lines = const LineSplitter().convert(response.body);
      final beers = <Beer>[];
      Brewery? currentBrewery;

      for (final line in lines) {
        // Neue Brauerei beginnt mit "- Brauerei Name"
        if (line.startsWith('-')) {
          final breweryName = line.substring(1).trim();
          // Finde passende Brauerei
          try {
            currentBrewery = breweriesMap.values.firstWhere(
              (b) =>
                  b.name.toLowerCase().contains(breweryName.toLowerCase()) ||
                  breweryName.toLowerCase().contains(b.name.toLowerCase()),
            );
          } catch (e) {
            // Wenn keine passende Brauerei gefunden, setze auf null
            currentBrewery = null;
          }
          continue;
        }

        final beer = _parseBeer(line, currentBrewery, region);
        if (beer != null) {
          beers.add(beer);
        }
      }

      return beers;
    } catch (e) {
      print('⚠️  Fehler beim Laden von $region Bieren: $e');
      return [];
    }
  }

  /// Importiert Brauereien in Firestore (Batched)
  Future<void> _importBreweries(List<Brewery> breweries) async {
    const batchSize = 500; // Firestore Limit
    final batches = <Future>[];

    for (var i = 0; i < breweries.length; i += batchSize) {
      final batch = _db.batch();
      final chunk = breweries.skip(i).take(batchSize);

      for (final brewery in chunk) {
        final ref = _db.collection('breweries').doc(brewery.id);
        batch.set(ref, brewery.toFirestore());
      }

      batches.add(batch.commit());
    }

    await Future.wait(batches);
  }

  /// Importiert Biere in Firestore (Batched)
  Future<void> _importBeers(List<Beer> beers) async {
    const batchSize = 500;
    final batches = <Future>[];

    for (var i = 0; i < beers.length; i += batchSize) {
      final batch = _db.batch();
      final chunk = beers.skip(i).take(batchSize);

      for (final beer in chunk) {
        final ref = _db.collection('beers').doc(beer.id);
        batch.set(ref, beer.toFirestore());
      }

      batches.add(batch.commit());
    }

    await Future.wait(batches);
  }

  /// Hauptimport-Funktion
  Future<void> importAustrianBeers() async {
    print('🍺 IMPORT ÖSTERREICHISCHER BIERE STARTET...\n');

    final allBreweries = <Brewery>[];
    final allBeers = <Beer>[];

    // 1. ALLE BRAUEREIEN LADEN
    print('📍 LADE BRAUEREIEN AUS ALLEN BUNDESLÄNDERN...\n');

    for (final entry in dataSources.entries) {
      print('   ${entry.key}...');
      final breweries = await _fetchBreweries(entry.value['breweries']!, entry.key);
      allBreweries.addAll(breweries);
    }

    print('\n✅ ${allBreweries.length} Brauereien geladen!');

    // Brauereien Map für schnellen Zugriff
    final breweriesMap = {
      for (final brewery in allBreweries) brewery.id: brewery
    };

    // 2. ALLE BIERE LADEN
    print('\n🍺 LADE BIERE AUS ALLEN BUNDESLÄNDERN...\n');

    for (final entry in dataSources.entries) {
      print('   ${entry.key}...');
      final beers = await _fetchBeers(entry.value['beers']!, entry.key, breweriesMap);
      allBeers.addAll(beers);
    }

    print('\n✅ ${allBeers.length} Biere geladen!');

    // 3. IN FIREBASE IMPORTIEREN
    print('\n🔥 IMPORTIERE IN FIREBASE...');

    await _importBreweries(allBreweries);
    await _importBeers(allBeers);

    print('\n📊 IMPORT ABGESCHLOSSEN!');
    print('   Brauereien: ${allBreweries.length}');
    print('   Biere:      ${allBeers.length}');
    print('\n🎉 Alle Daten sind jetzt in Firebase!\n');
  }
}

