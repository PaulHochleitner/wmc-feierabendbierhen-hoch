import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import './config/auth_gate.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'l10n/app_localizations.dart';
import 'services/locale_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize common locales used by the app
  await initializeDateFormatting();
  await LocaleService.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // listen to locale changes to rebuild the app
    LocaleService.locale.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocaleService.locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeierabendBierchen',
      theme: _buildBeerTheme(),
      locale: LocaleService.locale.value,
      supportedLocales: const [Locale('de'), Locale('en'), Locale('hr')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
      routes: {'/home': (context) => const AuthGate()},
    );
  }

  ThemeData _buildBeerTheme() {
    // Bier-Farbschema: Braun, Gold, Amber
    const Color beerBrown = Color(0xFF8B4513); // Sattes Braun
    const Color beerGold = Color(0xFFD4AF37); // Gold
    const Color beerAmber = Color(0xFFFF8C00); // Amber/Orange
    const Color beerDark = Color(0xFF5C3A1F); // Dunkles Braun
    const Color beerLight = Color(0xFFFFE4B5); // Helles Beige

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: beerBrown,
        primary: beerBrown,
        secondary: beerGold,
        tertiary: beerAmber,
        surface: beerLight,
        onPrimary: Colors.white,
        onSecondary: beerDark,
        onSurface: beerDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: beerBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: beerBrown,
        selectedItemColor: beerGold,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: beerBrown,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: beerBrown),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: beerGold, width: 2),
        ),
        filled: true,
        fillColor: beerLight.withOpacity(0.3),
      ),
      cardTheme: CardThemeData(
        color: beerLight,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
