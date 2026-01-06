/// Zentrale Konstanten für die App
class AppConstants {
  AppConstants._(); // Privater Konstruktor, da dies eine Utility-Klasse ist

  // App-Informationen
  static const String appName = 'FeierabendBierchen';
  static const String appTitle = 'FEIERABEND BIERCHEN';

  // Animationen
  static const Duration bubbleAnimationDuration = Duration(seconds: 4);
  static const int bubbleCount = 20;
  static const int beerTileBubbleCount = 15;

  // Layout
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double maxContentWidth = 800.0;

  // Bier-Berechnungen
  static const double standardBeerVolumeMl = 500.0; // ml
  static const double alcoholDensity = 0.8; // g/ml
  static const double maleAlcoholDistributionFactor = 0.68;
  static const double femaleAlcoholDistributionFactor = 0.55;

  // Validierung
  static const double minHeight = 1.0; // cm
  static const double maxHeight = 300.0; // cm
  static const double minWeight = 1.0; // kg
  static const double maxWeight = 500.0; // kg

  // Cache
  static const Duration beerCatalogCacheDuration = Duration(hours: 24);
  static const String beerCatalogLastFetchKey = 'beer_catalog_last_fetch';

  // SharedPreferences Keys
  static const String keyFirstLaunch = 'first_launch';
  static const String keyGuestMode = 'guest_mode';
  static const String keyUserEmail = 'user_email';

  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionBeers = 'beers';
  static const String subcollectionUserBeers = 'beers';

  // Gender-Werte
  static const String genderMale = 'male';
  static const String genderFemale = 'female';
  static const String genderOther = 'other';
}
