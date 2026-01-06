// BEISPIEL: Wie man saveUserData() verwendet
// Diese Datei zeigt, wie die saveUserData() Funktion aufgerufen wird

import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';

/// Beispiel 1: Einfacher Aufruf mit try-catch
Future<void> example1() async {
  final service = BeerFirestoreService();
  
  try {
    await service.saveUserData(
      height: 180.0,  // Größe in cm
      weight: 75.0,  // Gewicht in kg
      gender: 'male', // "male", "female" oder "other"
    );
    
    print('✅ User-Daten erfolgreich gespeichert!');
  } catch (e) {
    print('❌ Fehler: $e');
  }
}

/// Beispiel 2: Mit Validierung und User-Feedback
Future<void> example2(BuildContext context) async {
  final service = BeerFirestoreService();
  
  // Beispiel-Daten vom User
  double height = 175.0;
  double weight = 70.0;
  String gender = 'female';
  
  try {
    // Speichere in Firestore unter users/{userUID}
    await service.saveUserData(
      height: height,
      weight: weight,
      gender: gender,
    );
    
    // Erfolg - zeige Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daten erfolgreich gespeichert!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    // Fehler - zeige Fehlermeldung
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fehler: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Beispiel 3: Mit Loading-State
Future<void> example3(BuildContext context, Function(bool) setLoading) async {
  final service = BeerFirestoreService();
  
  setLoading(true);
  
  try {
    await service.saveUserData(
      height: 185.0,
      weight: 80.0,
      gender: 'male',
    );
    
    // Erfolg
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erfolgreich gespeichert!')),
      );
    }
  } catch (e) {
    // Fehler
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  } finally {
    setLoading(false);
  }
}

