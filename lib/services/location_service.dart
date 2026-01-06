import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Fragt Berechtigung ab und holt aktuellen Standort
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Prüfen ob Standortdienste aktiv sind
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Sucht nach einer Adresse/Ort (Geocoding)
  Future<Location?> searchLocation(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        return locations.first;
      }
    } catch (e) {
      // Fehler beim Suchen
    }
    return null;
  }

  /// Öffnet die App-Einstellungen für Berechtigungen
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Holt Adresse aus Koordinaten (Reverse Geocoding)
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.street ?? ''} ${place.thoroughfare ?? ''}, ${place.locality ?? ''}".trim().replaceAll(RegExp(r'^, |^ '), '');
      }
    } catch (_) {}
    return null;
  }
}