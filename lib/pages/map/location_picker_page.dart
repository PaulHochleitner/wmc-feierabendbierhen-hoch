import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:feierabendbierchen_flutter/services/location_service.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final LocationService _locationService = LocationService();
  LatLng? _pickedLocation;
  bool _isLoading = true;

  // Standard: Wien (Fallback, falls GPS aus ist)
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(48.2082, 16.3738),
    zoom: 12,
  );

  CameraPosition _initialPosition = _defaultPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await _locationService.getCurrentLocation();
      if (pos != null) {
        setState(() {
          _initialPosition = CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 15,
          );
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des Standorts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  Future<void> _confirmLocation() async {
    if (_pickedLocation == null) return;

    setState(() => _isLoading = true);

    try {
      // Adresse aus Koordinaten ermitteln (Reverse Geocoding)
      final address = await _locationService.getAddressFromCoordinates(
        _pickedLocation!.latitude,
        _pickedLocation!.longitude,
      );

      if (mounted) {
        Navigator.of(context).pop({
          'lat': _pickedLocation!.latitude,
          'lng': _pickedLocation!.longitude,
          'name': address ?? 'Ausgewählter Ort',
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop({
          'lat': _pickedLocation!.latitude,
          'lng': _pickedLocation!.longitude,
          'name': 'Unbekannter Ort',
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Standort auf Karte wählen'),
        backgroundColor: const Color(0xFF1F1B16),
        foregroundColor: const Color(0xFFFFD700),
        actions: [
          if (_pickedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmLocation,
              tooltip: 'Standort übernehmen',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            )
          : GoogleMap(
              initialCameraPosition: _initialPosition,
              onTap: _onTap,
              markers: _pickedLocation != null
                  ? {
                      Marker(
                        markerId: const MarkerId('picked'),
                        position: _pickedLocation!,
                      ),
                    }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}
