import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';
import 'package:feierabendbierchen_flutter/l10n/app_localizations.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:feierabendbierchen_flutter/pages/beer/beer_page.dart';
import 'package:feierabendbierchen_flutter/services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:feierabendbierchen_flutter/pages/map/location_picker_page.dart';

class ConsumptionDiaryPage extends StatefulWidget {
  const ConsumptionDiaryPage({super.key});

  @override
  State<ConsumptionDiaryPage> createState() => _ConsumptionDiaryPageState();
}

enum SortOption { dateDesc, dateAsc, promilleDesc, promilleAsc }

class _ConsumptionDiaryPageState extends State<ConsumptionDiaryPage> {
  final BeerFirestoreService _firestoreService = BeerFirestoreService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  List<DocumentSnapshot> _beers = [];

  // Filter & Sort
  SortOption _sortOption = SortOption.dateDesc;
  String _beerFilter = '';
  String? _countryFilter;
  final TextEditingController _beerFilterController = TextEditingController();
  final TextEditingController _countryFilterController =
      TextEditingController();

  // Bier-Datenbank
  final Map<String, List<Map<String, dynamic>>> _beerDatabase = {
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _beerFilterController.dispose();
    _countryFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final profile = await _firestoreService.getUserProfile();
      final beersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('beers')
          .orderBy('date', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _beers = beersSnapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _calculatePromille(DocumentSnapshot doc) {
    if (_userProfile == null) return 0.0;

    final data = doc.data() as Map<String, dynamic>;
    double alc = (data['percentage'] ?? 0.0).toDouble();

    // Formel: 500ml * (alc/100) * 0.8 / (Gewicht * r)
    double alcoholGrams = 500 * (alc / 100.0) * 0.8;
    double r = _userProfile!.gender == 'female' ? 0.55 : 0.68;
    double weight = _userProfile!.weight;

    if (weight > 0) {
      return alcoholGrams / (weight * r);
    }
    return 0.0;
  }

  double _calculatePromilleFromBeer(ConsumedBeer beer) {
    if (_userProfile == null) return 0.0;
    double alc = beer.percentage;
    double alcoholGrams = 500 * (alc / 100.0) * 0.8;
    double r = _userProfile!.gender == 'female' ? 0.55 : 0.68;
    double weight = _userProfile!.weight;
    if (weight > 0) {
      return alcoholGrams / (weight * r);
    }
    return 0.0;
  }

  List<DocumentSnapshot> _getFilteredAndSortedBeers() {
    final lowerQuery = _beerFilter.toLowerCase();

    List<DocumentSnapshot> filtered = _beers.where((doc) {
      final beer = ConsumedBeer.fromFirestore(doc);
      final matchesName = beer.name.toLowerCase().contains(lowerQuery);
      final matchesCountry = _countryFilter == null || _countryFilter!.isEmpty
          ? true
          : beer.country.toLowerCase() == _countryFilter!.toLowerCase();
      return matchesName && matchesCountry;
    }).toList();

    filtered.sort((a, b) {
      final beerA = ConsumedBeer.fromFirestore(a);
      final beerB = ConsumedBeer.fromFirestore(b);
      switch (_sortOption) {
        case SortOption.dateDesc:
          return beerB.date.compareTo(beerA.date);
        case SortOption.dateAsc:
          return beerA.date.compareTo(beerB.date);
        case SortOption.promilleDesc:
          return _calculatePromilleFromBeer(
            beerB,
          ).compareTo(_calculatePromilleFromBeer(beerA));
        case SortOption.promilleAsc:
          return _calculatePromilleFromBeer(
            beerA,
          ).compareTo(_calculatePromilleFromBeer(beerB));
      }
    });

    return filtered;
  }

  void _showBeerDialog({ConsumedBeer? existingBeer}) {
    // Direkt den Beer-Dialog öffnen, ohne extra BeerPage-Wrapper
    final beerToEdit = existingBeer;
    String? selectedCountry = beerToEdit?.country;
    Map<String, dynamic>? selectedBeerData;

    if (beerToEdit != null && selectedCountry != null) {
      // Suche das exakte Map-Objekt in der Datenbank
      final beers = _beerDatabase[selectedCountry];
      if (beers != null) {
        try {
          selectedBeerData = beers.firstWhere(
            (b) => b['name'] == beerToEdit.name,
          );
        } catch (_) {
          // Falls nicht gefunden, bleibt es null
        }
      }
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingBeer != null
                        ? AppLocalizations.of(context).t('add_entry')
                        : AppLocalizations.of(context).t('new_beer'),
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
                    value: selectedCountry,
                    dropdownColor: const Color(0xFF2D241E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Herkunftsland",
                      labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF8D6E63)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFFFD700)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _beerDatabase.keys.map((country) {
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
                    value: selectedBeerData,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D241E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Bier Auswahl",
                      labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF8D6E63)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFFFD700)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: selectedCountry == null
                        ? []
                        : _beerDatabase[selectedCountry]!.map((beer) {
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

                  // Standort Auswahl (Kopie von BeerPage Logik)
                  Text(
                    "STANDORT",
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF8D6E63)),
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
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // GPS Button
                        IconButton(
                          icon: const Icon(
                            Icons.my_location,
                            color: Color(0xFFFFD700),
                          ),
                          onPressed: () async {
                            final locService = LocationService();
                            final pos = await locService.getCurrentLocation();
                            if (pos != null) {
                              final address = await locService
                                  .getAddressFromCoordinates(
                                    pos.latitude,
                                    pos.longitude,
                                  );
                              setModalState(() {
                                latitude = pos.latitude;
                                longitude = pos.longitude;
                                locationName = address ?? "Mein Standort";
                              });
                            }
                          },
                        ),
                        // Suche Button
                        IconButton(
                          icon: const Icon(Icons.map, color: Color(0xFFFFD700)),
                          tooltip: "Karte öffnen",
                          onPressed: () async {
                            final result =
                                await Navigator.push<Map<String, dynamic>>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LocationPickerPage(),
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
                  ),
                  const SizedBox(height: 24),

                  // Bewertung
                  Text(
                    "${AppLocalizations.of(context).t('taste')}: ${rating.toInt()}",
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Grafische 1-5 Sterne Auswahl
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < rating.toInt();
                      return Semantics(
                        label:
                            '${i + 1} ${AppLocalizations.of(context).t('star')}',
                        button: true,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          tooltip:
                              '${i + 1} ${AppLocalizations.of(context).t('star')}',
                          icon: Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: filled
                                ? const Color(0xFFFFD700)
                                : Colors.grey[600],
                            size: 32,
                          ),
                          onPressed: () {
                            setModalState(() => rating = (i + 1).toDouble());
                          },
                        ),
                      );
                    }),
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
                                  ).toMap();

                                  final collection = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('beers');

                                  if (beerToEdit != null &&
                                      beerToEdit.id != null) {
                                    // Update existing
                                    await collection
                                        .doc(beerToEdit.id)
                                        .update(beerData);
                                  } else {
                                    // Add new
                                    await collection.add(beerData);
                                  }

                                  Navigator.pop(context);
                                  _loadData();
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
            );
          },
        );
      },
    );
  }

  void _showBeerDetails(DocumentSnapshot doc) {
    final beer = ConsumedBeer.fromFirestore(doc);
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['date'] as Timestamp).toDate();
    final promille = _calculatePromille(doc);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF12100E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DETAILS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm', 'de').format(date),
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Details
            _buildDetailRow('Bier', beer.name, Icons.local_drink),
            const SizedBox(height: 16),
            _buildDetailRow('Land', beer.country, Icons.public),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Alkoholgehalt',
              '${beer.percentage.toStringAsFixed(1)} %',
              Icons.science,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Bewertung', '${beer.rating}/5 ⭐', Icons.star),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Promille',
              '${promille.toStringAsFixed(2)} ‰',
              Icons.speed,
              highlight: true,
            ),

            // Karte anzeigen wenn Koordinaten vorhanden
            if (beer.latitude != null && beer.longitude != null) ...[
              const SizedBox(height: 24),
              Text(
                "GETRUNKEN IN: ${beer.locationName ?? ''}",
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(beer.latitude!, beer.longitude!),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('beer_loc'),
                        position: LatLng(beer.latitude!, beer.longitude!),
                      ),
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showBeerDialog(existingBeer: beer);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD700),
                      side: const BorderSide(color: Color(0xFFFFD700)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('BEARBEITEN'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1C1917),
                          title: const Text(
                            'Löschen?',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Möchtest du diesen Eintrag wirklich löschen?',
                            style: TextStyle(color: Colors.grey),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                'Abbrechen',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Löschen',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && beer.id != null) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('beers')
                              .doc(beer.id)
                              .delete();

                          if (mounted) {
                            Navigator.pop(context); // Close details only
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Eintrag gelöscht'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('LÖSCHEN'),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFFD700).withOpacity(0.1)
            : const Color(0xFF1C1917),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? const Color(0xFFFFD700) : Colors.grey[800]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: highlight ? const Color(0xFFFFD700) : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: highlight ? const Color(0xFFFFD700) : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return Scaffold(
      backgroundColor: const Color(0xFF12100E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'KONSUM-TAGEBUCH',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            )
          : _buildContent(bottomPadding),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBeerDialog(),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'EINTRAG HINZUFÜGEN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContent(double bottomPadding) {
    final filtered = _getFilteredAndSortedBeers();

    if (filtered.isEmpty) {
      return Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_drink_outlined,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keine Einträge',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Passe Filter an oder füge ein Bier hinzu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFFFFD700),
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final doc = filtered[index];
                final beer = ConsumedBeer.fromFirestore(doc);
                final data = doc.data() as Map<String, dynamic>;
                final date = (data['date'] as Timestamp).toDate();
                final promille = _calculatePromille(doc);

                return _buildBeerCard(beer, date, promille, doc);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    // Alle Länder aus der Bier-Datenbank (nicht nur bereits getrunkene)
    final countries = _beerDatabase.keys.toList()..sort();
    // Bierliste nur aus dem aktuell gewählten Land
    final beerNames = (_countryFilter != null && _countryFilter!.isNotEmpty)
        ? ((_beerDatabase[_countryFilter] ?? [])
              .map((b) => b['name'] as String)
              .toList()
            ..sort())
        : <String>[];

    const labelStyle = TextStyle(color: Color(0xFFFFD700));
    const fillColor = Color(0x33FFD700); // leichtes Orange
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFFFD700)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<SortOption>(
                  value: _sortOption,
                  dropdownColor: const Color(0xFF1C1917),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Sortierung',
                    labelStyle: labelStyle,
                    filled: true,
                    fillColor: fillColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFFFFD700)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                        color: Color(0xFFFFD700),
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: SortOption.dateDesc,
                      child: Text('Datum ↓'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.dateAsc,
                      child: Text('Datum ↑'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.promilleDesc,
                      child: Text('Promille ↓'),
                    ),
                    DropdownMenuItem(
                      value: SortOption.promilleAsc,
                      child: Text('Promille ↑'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortOption = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.isEmpty) return countries;
                    final query = value.text.toLowerCase();
                    return countries
                        .where((c) => c.toLowerCase().contains(query))
                        .toList();
                  },
                  initialValue: TextEditingValue(text: _countryFilter ?? ''),
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                    _countryFilterController.value = controller.value;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFFFFD700),
                      decoration: InputDecoration(
                        labelText: 'Herkunftsland filtern',
                        labelStyle: labelStyle,
                        filled: true,
                        fillColor: fillColor,
                        enabledBorder: border,
                        focusedBorder: border.copyWith(
                          borderSide: const BorderSide(
                            color: Color(0xFFFFD700),
                            width: 1.5,
                          ),
                        ),
                        suffixIcon:
                            _countryFilter != null && _countryFilter!.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFFFFD700),
                                ),
                                onPressed: () {
                                  controller.clear();
                                  setState(() {
                                    _countryFilter = null;
                                    _countryFilterController.clear();
                                    _beerFilter = '';
                                    _beerFilterController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _countryFilter = val.isEmpty ? null : val;
                          _beerFilter = '';
                          _beerFilterController.clear();
                        });
                      },
                    );
                  },
                  onSelected: (value) {
                    setState(() {
                      _countryFilter = value;
                      _countryFilterController.text = value;
                      _beerFilter = '';
                      _beerFilterController.clear();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_countryFilter != null && _countryFilter!.isNotEmpty)
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                if (value.text.isEmpty) return beerNames;
                final query = value.text.toLowerCase();
                return beerNames
                    .where((name) => name.toLowerCase().contains(query))
                    .toList();
              },
              initialValue: TextEditingValue(text: _beerFilter),
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                _beerFilterController.value = controller.value;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFFFFD700),
                  decoration: InputDecoration(
                    labelText: 'Bier (im Land) filtern',
                    labelStyle: labelStyle,
                    filled: true,
                    fillColor: fillColor,
                    enabledBorder: border,
                    focusedBorder: border.copyWith(
                      borderSide: const BorderSide(
                        color: Color(0xFFFFD700),
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: _beerFilter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Color(0xFFFFD700),
                            ),
                            onPressed: () {
                              controller.clear();
                              setState(() {
                                _beerFilter = '';
                                _beerFilterController.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _beerFilter = val;
                    });
                  },
                );
              },
              onSelected: (value) {
                setState(() {
                  _beerFilter = value;
                  _beerFilterController.text = value;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBeerCard(
    ConsumedBeer beer,
    DateTime date,
    double promille,
    DocumentSnapshot doc,
  ) {
    final isToday =
        DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1C1917),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isToday
              ? const Color(0xFFFFD700).withOpacity(0.5)
              : Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showBeerDetails(doc),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_drink,
                  color: Color(0xFFFFD700),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      beer.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isToday
                              ? 'Heute, ${DateFormat('HH:mm', 'de').format(date)}'
                              : DateFormat(
                                  'dd.MM.yyyy HH:mm',
                                  'de',
                                ).format(date),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${beer.percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_userProfile != null && promille > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${promille.toStringAsFixed(2)} ‰',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < beer.rating ? Icons.star : Icons.star_border,
                              size: 16,
                              color: i < beer.rating
                                  ? const Color(0xFFFFD700)
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
