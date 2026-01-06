import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/location_service.dart';
import '../../pages/map/location_picker_page.dart';
import '../../models/consumed_beer.dart';
import '../../core/data/beer_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/beer/beer_list_tile.dart';
import '../../repositories/beer_repository.dart';

class BeerPage extends StatefulWidget {
  final ConsumedBeer? existingBeer;
  final VoidCallback? onSaved;

  const BeerPage({super.key, this.existingBeer, this.onSaved});

  @override
  State<BeerPage> createState() => _BeerPageState();
}

class _BeerPageState extends State<BeerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final BeerRepository _beerRepository = BeerRepository();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.bubbleAnimationDuration,
    )..repeat();

    // Öffne Dialog automatisch wenn existingBeer gesetzt ist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.existingBeer != null) {
        _showAddBeerDialog();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddBeerDialog({ConsumedBeer? existingBeer}) {
    final beerToEdit = existingBeer ?? widget.existingBeer;
    String? selectedCountry = beerToEdit?.country;
    Map<String, dynamic>? selectedBeerData;

    if (beerToEdit != null && selectedCountry != null) {
      // Suche das exakte Map-Objekt in der Datenbank für die Referenz-Gleichheit im Dropdown
      selectedBeerData = BeerDatabase.findBeer(selectedCountry, beerToEdit.name);
    }

    double rating = beerToEdit?.rating.toDouble() ?? 5.0;
    DateTime selectedDate = beerToEdit?.date ?? DateTime.now();

    // Standort State
    double? latitude = beerToEdit?.latitude;
    double? longitude = beerToEdit?.longitude;
    String? locationName = beerToEdit?.locationName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F1B16),
      constraints: const BoxConstraints(maxWidth: 600),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF8D6E63), width: 1),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existingBeer != null
                          ? "BIER BEARBEITEN"
                          : "NEUES BIER ZAPFEN",
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Land Auswahl
                    DropdownButtonFormField<String>(
                      initialValue: selectedCountry,
                      dropdownColor: const Color(0xFF2D241E),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Herkunftsland",
                        labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF8D6E63),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFFFFD700),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: BeerDatabase.getCountries().map((country) {
                        return DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedCountry = value;
                          selectedBeerData =
                              null; // Reset beer when country changes
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Bier Auswahl
                    DropdownButtonFormField<Map<String, dynamic>>(
                      initialValue:
                          selectedBeerData, // Hier müsste man eigentlich das Objekt matchen, vereinfacht
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2D241E),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Bier Auswahl",
                        labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF8D6E63),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFFFFD700),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: selectedCountry == null
                          ? []
                          : (BeerDatabase.getBeersByCountry(selectedCountry!) ?? []).map((beer) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: beer,
                                child: Text(
                                  beer['name'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                      onChanged: selectedCountry == null
                          ? null
                          : (value) {
                              setModalState(() {
                                selectedBeerData = value;
                              });
                            },
                    ),

                    if (selectedBeerData != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Alkoholgehalt: ${selectedBeerData!['alc'].toString()} %",
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Datum Auswahl
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFFFFD700),
                                  onPrimary: Colors.black,
                                  surface: Color(0xFF1F1B16),
                                  onSurface: Colors.white,
                                ),
                                dialogTheme: DialogThemeData(
                                  backgroundColor: const Color(0xFF1F1B16),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && picked != selectedDate) {
                          setModalState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF8D6E63)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Datum: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Standort Auswahl
                    Text(
                      "STANDORT",
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Standort Logik mit Live-Update
                    FutureBuilder<bool>(
                      future: LocationService().isLocationServiceEnabled(),
                      builder: (context, snapshot) {
                        final bool initialStatus = snapshot.data ?? false;

                        return StreamBuilder<bool>(
                          stream: LocationService().locationStatusStream,
                          initialData: initialStatus,
                          builder: (context, streamSnapshot) {
                            // Buttons immer aktivieren
                            const Color iconColor = Color(0xFFFFD700);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF8D6E63),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: locationName != null
                                        ? Colors.redAccent
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      locationName ?? "Kein Standort markiert",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // GPS Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.my_location,
                                      color: iconColor,
                                    ),
                                    tooltip: "Aktuellen Standort verwenden",
                                    onPressed: () async {
                                            final locService =
                                                LocationService();
                                            final pos = await locService
                                                .getCurrentLocation();
                                            if (pos != null) {
                                              final address = await locService
                                                  .getAddressFromCoordinates(
                                                    pos.latitude,
                                                    pos.longitude,
                                                  );
                                              setModalState(() {
                                                latitude = pos.latitude;
                                                longitude = pos.longitude;
                                                locationName =
                                                    address ?? "Mein Standort";
                                              });
                                            }
                                          },
                                  ),
                                  // Karte Button
                                  IconButton(
                                    icon: const Icon(Icons.map, color: iconColor),
                                    tooltip: "Karte öffnen",
                                    onPressed: () async {
                                            final result =
                                                await Navigator.push<
                                                  Map<String, dynamic>
                                                >(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        LocationPickerPage(),
                                                  ),
                                                );

                                            if (result != null) {
                                              setModalState(() {
                                                latitude = result['lat'];
                                                longitude = result['lng'];
                                                locationName = result['name'];
                                              });
                                            }
                                          },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),

                    if (locationName == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4),
                        child: GestureDetector(
                          onTap: () => LocationService().openLocationSettings(),
                          child: Text(
                            "GPS Einstellungen öffnen",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Bewertung
                    Text(
                      "GESCHMACK (1-10): ${rating.toInt()}",
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFFD700),
                        inactiveTrackColor: const Color(0xFF5D4037),
                        thumbColor: const Color(0xFFFFD700),
                        overlayColor: const Color(0xFFFFD700).withOpacity(0.2),
                      ),
                      child: Slider(
                        value: rating,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: rating.toInt().toString(),
                        onChanged: (value) {
                          setModalState(() => rating = value);
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed:
                                (selectedCountry != null &&
                                    selectedBeerData != null)
                                ? () async {
                                    final user =
                                        FirebaseAuth.instance.currentUser;
                                    if (user == null) return;

                                    final beerData = ConsumedBeer(
                                      name: selectedBeerData!['name'],
                                      country: selectedCountry!,
                                      percentage: selectedBeerData!['alc'],
                                      rating: rating.toInt(),
                                      date: selectedDate,
                                      latitude: latitude,
                                      longitude: longitude,
                                      locationName: locationName,
                                    ).toFirestore();

                                    final collection = FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('beers');

                                    final beerToUpdate =
                                        existingBeer ?? widget.existingBeer;
                                    if (beerToUpdate != null &&
                                        beerToUpdate.id != null) {
                                      // Update existing
                                      await _beerRepository.updateBeer(
                                        beerToUpdate.copyWith(
                                          name: selectedBeerData!['name'],
                                          country: selectedCountry!,
                                          percentage: selectedBeerData!['alc'],
                                          rating: rating.toInt(),
                                          date: selectedDate,
                                          latitude: latitude,
                                          longitude: longitude,
                                          locationName: locationName,
                                        ),
                                      );
                                    } else {
                                      // Add new
                                      await _beerRepository.addBeer(
                                        ConsumedBeer(
                                          name: selectedBeerData!['name'],
                                          country: selectedCountry!,
                                          percentage: selectedBeerData!['alc'],
                                          rating: rating.toInt(),
                                          date: selectedDate,
                                          latitude: latitude,
                                          longitude: longitude,
                                          locationName: locationName,
                                        ),
                                      );
                                    }

                                    if (widget.onSaved != null) {
                                      widget.onSaved!();
                                    }
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              existingBeer != null ? "SPEICHERN" : "HINZUFÜGEN",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const SizedBox(); // Should not happen due to AuthGate

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<ConsumedBeer>>(
        stream: _beerRepository.getBeersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Fehler beim Laden",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.beerAccentGold),
            );
          }

          final beers = snapshot.data ?? [];

          if (beers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFFC107,
                              ).withOpacity(0.3 * _controller.value),
                              blurRadius: 10 + (15 * _controller.value),
                              spreadRadius: 2 + (5 * _controller.value),
                            ),
                            BoxShadow(
                              color: const Color(0xFFFFA000).withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_drink,
                          size: 100,
                          color: Color(0xFFFFD700),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Noch kein Bier? 🍺",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        BoxShadow(
                          color: const Color(0xFFFFA000).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Drücke auf + um dein erstes Bier zu zapfen",
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFFD7CCC8),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: beers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final beer = beers[index];
              return BeerListTile(
                beer: beer,
                animation: _controller,
                onEdit: () => _showAddBeerDialog(existingBeer: beer),
                onDelete: () async {
                  if (beer.id != null) {
                    await _beerRepository.deleteBeer(beer.id!);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddBeerDialog(),
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text(
            "BIER HINZUFÜGEN",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

