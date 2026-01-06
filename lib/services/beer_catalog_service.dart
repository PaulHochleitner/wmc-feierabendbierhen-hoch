import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BeerCatalogService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Key für SharedPreferences zum Speichern des Zeitstempels
  static const String _kLastFetchKey = 'beer_catalog_last_fetch';

  // Cache-Gültigkeit: 24 Stunden
  // Das bedeutet: Wir laden nur 1x alle 24h vom Server (kostet Geld),
  // sonst nehmen wir den lokalen Cache (gratis & schnell).
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Lädt die Liste aller verfügbaren Biere (Katalog).
  ///
  /// Implementiert eine "Cache-First" Strategie mit Zeitprüfung:
  /// 1. Prüfe wann zuletzt vom Server geladen wurde.
  /// 2. Wenn < 24h: Versuche erst Cache (Source.cache).
  /// 3. Wenn > 24h oder Cache leer: Lade vom Server (Source.server).
  Future<List<Map<String, dynamic>>> getBeers() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchMillis = prefs.getInt(_kLastFetchKey);
    final lastFetch = lastFetchMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(lastFetchMillis)
        : null;

    final now = DateTime.now();

    // Entscheidung: Cache oder Server?
    // Server wenn: Noch nie geladen ODER Cache älter als 24h
    bool shouldFetchFromServer =
        lastFetch == null || now.difference(lastFetch) > _cacheDuration;

    try {
      // 1. Versuch: Cache nutzen (wenn Daten aktuell genug sind)
      if (!shouldFetchFromServer) {
        try {
          debugPrint(
            '🍺 BeerCatalogService: Cache ist aktuell (< 24h). Lade aus lokalem Cache...',
          );

          // Source.cache zwingt Firestore, NICHT ins Netzwerk zu gehen -> 0 Reads Kosten
          final snapshot = await _db
              .collection('beers')
              .orderBy('name')
              .get(const GetOptions(source: Source.cache));

          if (snapshot.docs.isNotEmpty) {
            debugPrint(
              '✅ BeerCatalogService: ${snapshot.docs.length} Biere aus Cache geladen.',
            );
            return snapshot.docs.map((d) => d.data()).toList();
          }
          debugPrint(
            '⚠️ BeerCatalogService: Cache war leer, wechsle zu Server.',
          );
        } catch (e) {
          debugPrint('⚠️ BeerCatalogService: Fehler beim Cache-Zugriff: $e');
          // Fallback zu Server passiert automatisch unten
        }
      }

      // 2. Versuch: Server (wenn Cache alt, leer oder Fehler)
      debugPrint('🌍 BeerCatalogService: Lade frisch vom Server...');

      // Source.server zwingt Firestore, das Netzwerk zu nutzen
      final snapshot = await _db
          .collection('beers')
          .orderBy('name')
          .get(const GetOptions(source: Source.server));

      // Timestamp aktualisieren (nur bei erfolgreichem Server-Call)
      await prefs.setInt(_kLastFetchKey, now.millisecondsSinceEpoch);
      debugPrint(
        '✅ BeerCatalogService: ${snapshot.docs.length} Biere vom Server geladen. Cache aktualisiert.',
      );

      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('❌ BeerCatalogService: Fehler beim Laden: $e');

      // 3. Notfall-Fallback: Versuche Cache, auch wenn er "zu alt" ist (besser als nichts bei Offline/Fehler)
      try {
        debugPrint('🆘 BeerCatalogService: Versuche Notfall-Cache...');
        final snapshot = await _db
            .collection('beers')
            .orderBy('name')
            .get(const GetOptions(source: Source.cache));
        return snapshot.docs.map((d) => d.data()).toList();
      } catch (_) {
        debugPrint('☠️ BeerCatalogService: Auch Notfall-Cache fehlgeschlagen.');
        return [];
      }
    }
  }
}
