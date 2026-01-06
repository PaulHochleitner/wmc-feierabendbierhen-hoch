/// Zentrale Bier-Datenbank mit allen verfügbaren Bieren
class BeerDatabase {
  BeerDatabase._(); // Privater Konstruktor

  /// Statische Bier-Datenbank nach Ländern organisiert
  static const Map<String, List<Map<String, dynamic>>> beers = {
    "🇦🇹 Österreich": [
      {"name": "Gösser Export (Dortmunder Export)", "alc": 5.0},
      {"name": "Gösser Märzen", "alc": 5.2},
      {"name": "Gösser Zwickl", "alc": 5.2},
      {"name": "Stiegl Goldbräu", "alc": 5.0},
      {"name": "Stiegl Max Glaner's IPA", "alc": 6.2},
      {"name": "Ottakringer Wiener Original (Wiener Lager)", "alc": 5.3},
      {"name": "Ottakringer Helles", "alc": 5.2},
      {"name": "Ottakringer Dunkles", "alc": 5.3},
      {"name": "Ottakringer Bio Zwickl", "alc": 5.3},
      {"name": "Ottakringer Radler Citrus", "alc": 2.0},
      {"name": "Puntigamer Märzen", "alc": 5.4},
      {"name": "Schwechater Zwickl", "alc": 5.0},
      {"name": "Zipfer Urtyp", "alc": 5.0},
      {"name": "Zipfer Märzen", "alc": 5.4},
      {"name": "Zillertal Schwarzbier", "alc": 4.9},
      {"name": "Hubertus Dunkles Märzenbier", "alc": 5.2},
      {"name": "Zwettler Zwickl", "alc": 5.3},
      {"name": "Egger Märzen", "alc": 5.0},
      {"name": "Edelweiss Hefetrüb", "alc": 5.3},
      {"name": "Brew Age Alpha Tier IPA", "alc": 6.5},
      {"name": "Brew Age Chic Xulub Oatmeal Stout", "alc": 6.8},
      {"name": "Brew Age Dunkle Materie Black IPA", "alc": 6.0},
    ],
    "🇩🇪 Deutschland": [
      {"name": "Weihenstephaner Hefeweißbier", "alc": 5.4},
      {"name": "Paulaner Hefe-Weißbier Naturtrüb", "alc": 5.5},
      {"name": "Paulaner Oktoberfest Märzen", "alc": 6.0},
      {"name": "Augustiner Bräu Helles Lagerbier", "alc": 5.2},
      {"name": "Ayinger Bavarian Pils", "alc": 5.3},
      {"name": "Ayinger Celebrator Doppelbock", "alc": 6.7},
      {"name": "Bitburger Premium Pils", "alc": 4.8},
      {"name": "Hacker-Pschorr Original Oktoberfest Märzen", "alc": 5.8},
      {"name": "Hofbräu Original", "alc": 5.1},
      {"name": "Hofbräu Dunkel", "alc": 5.5},
      {"name": "Köstritzer Schwarzbier", "alc": 4.8},
      {"name": "Warsteiner Premium Verum", "alc": 4.8},
      {"name": "Radeberger Pilsner", "alc": 4.8},
      {"name": "Krombacher Pils", "alc": 4.8},
      {"name": "Veltins Pilsener", "alc": 4.8},
      {"name": "Flensburger Pilsener", "alc": 4.8},
      {"name": "Diebels Altbier", "alc": 4.9},
      {"name": "Darmstädter 1847 Zwickelbier", "alc": 5.3},
    ],
    "🇳🇱 Niederlande": [
      {"name": "Heineken Original Lager Beer", "alc": 5.0},
      {"name": "Amstel Pilsener", "alc": 5.0},
      {"name": "Grolsch Premium Pilsner", "alc": 5.0},
      {"name": "Bavaria Premium Pilsener", "alc": 5.0},
      {"name": "Alfa Edel Pils", "alc": 5.0},
      {"name": "Egmondse Blonde Ale", "alc": 6.5},
      {"name": "Egmondse Tripel", "alc": 7.5},
    ],
    "🇭🇷 Kroatien": [
      {"name": "Ožujsko Pivo", "alc": 5.0},
      {"name": "Karlovačko Svijetlo Lager", "alc": 5.0},
      {"name": "Karlovačko Crno (Dark Lager)", "alc": 5.4},
    ],
  };

  /// Gibt alle Länder zurück
  static List<String> getCountries() {
    return beers.keys.toList()..sort();
  }

  /// Gibt alle Biere eines Landes zurück
  static List<Map<String, dynamic>>? getBeersByCountry(String country) {
    return beers[country];
  }

  /// Sucht ein Bier nach Name und Land
  static Map<String, dynamic>? findBeer(String country, String name) {
    final countryBeers = beers[country];
    if (countryBeers == null) return null;

    try {
      return countryBeers.firstWhere(
        (beer) => beer['name'] == name,
      );
    } catch (_) {
      return null;
    }
  }
}
