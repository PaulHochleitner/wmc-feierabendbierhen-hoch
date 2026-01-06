import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Prüfe Berechtigungen
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Fallback wenn abgelehnt
        _setDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      _updateLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      debugPrint("Fehler beim Laden des Standorts: $e");
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        // Default: Berlin (oder ein anderer Standardwert)
        _selectedLocation = LatLng(52.5200, 13.4050);
      });
    }
  }

  void _updateLocation(LatLng position) {
    if (mounted) {
      setState(() {
        _selectedLocation = position;
        _isLoading = false;
      });
      _mapController.move(position, 15.0);
    }
  }

  Future<void> _confirmSelection() async {
    if (_selectedLocation == null) return;

    String locationName = "Ausgewählter Ort";
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        locationName =
            "${place.street ?? ''} ${place.thoroughfare ?? ''}, ${place.locality ?? ''}"
                .trim();
        locationName = locationName
            .replaceAll(RegExp(r'^, |^ '), '')
            .replaceAll(RegExp(r', $'), '');
        if (locationName.isEmpty) {
          locationName = place.locality ?? "Unbekannter Ort";
        }
      }
    } catch (e) {
      debugPrint("Geocoding Fehler: $e");
    }

    if (mounted) {
      Navigator.pop(context, {
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
        'name': locationName,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Standort wählen"),
        backgroundColor: const Color(0xFF1F1B16),
        foregroundColor: const Color(0xFFFFD700),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            // Button ist nur aktiv, wenn ein Standort (auch per GPS) gefunden wurde
            onPressed: _selectedLocation != null ? _confirmSelection : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation ?? LatLng(52.5200, 13.4050),
                initialZoom: 15.0,
                onTap: (tapPosition, point) => _updateLocation(point),
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.feierabendbierchen.app',
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}
