import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BeerPage extends StatefulWidget {
  const BeerPage({super.key});

  @override
  State<BeerPage> createState() => _BeerPageState();
}

class _BeerPageState extends State<BeerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Bier-Datenbank
  final Map<String, List<Map<String, dynamic>>> _beerDatabase = {
    "🇦🇹 Österreich": [
      {"name": "Gösser Export (Dortmunder Export)", "alc": 5.0},
      {"name": "Gösser Märzen", "alc": 5.2},
      {"name": "Gösser Zwickl", "alc": 5.2},
      {"name": "Stiegl Goldbräu", "alc": 5.0},
      {"name": "Stiegl Max Glaner’s IPA", "alc": 6.2},
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddBeerDialog({ConsumedBeer? existingBeer}) {
    String? selectedCountry = existingBeer?.country;
    Map<String, dynamic>? selectedBeerData;

    if (existingBeer != null && selectedCountry != null) {
      // Suche das exakte Map-Objekt in der Datenbank für die Referenz-Gleichheit im Dropdown
      final beers = _beerDatabase[selectedCountry];
      if (beers != null) {
        try {
          selectedBeerData = beers.firstWhere((b) => b['name'] == existingBeer.name);
        } catch (_) {
          // Falls nicht gefunden (z.B. Name geändert), bleibt es null
        }
      }
    }

    double rating = existingBeer?.rating.toDouble() ?? 5.0;
    DateTime selectedDate = existingBeer?.date ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F1B16),
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
                bottom: MediaQuery.of(context).viewInsets.bottom + 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingBeer != null ? "BIER BEARBEITEN" : "NEUES BIER ZAPFEN",
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
                        selectedBeerData = null; // Reset beer when country changes
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Bier Auswahl
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: selectedBeerData, // Hier müsste man eigentlich das Objekt matchen, vereinfacht
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
                    onChanged: selectedCountry == null ? null : (value) {
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
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFFFD700)),
                          const SizedBox(width: 10),
                          Text(
                            "Alkoholgehalt: ${selectedBeerData!['alc'].toString()} %",
                            style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
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
                              dialogBackgroundColor: const Color(0xFF1F1B16),
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
                          const Icon(Icons.calendar_today, color: Color(0xFFFFD700)),
                          const SizedBox(width: 12),
                          Text(
                            "Datum: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Bewertung
                  Text(
                    "GESCHMACK (1-10): ${rating.toInt()}",
                    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
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
                          onPressed: (selectedCountry != null && selectedBeerData != null) ? () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            final beerData = ConsumedBeer(
                              name: selectedBeerData!['name'],
                              country: selectedCountry!,
                              percentage: selectedBeerData!['alc'],
                              rating: rating.toInt(),
                              date: selectedDate,
                            ).toMap();
                            
                            final collection = FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('beers');

                            if (existingBeer != null && existingBeer.id != null) {
                              // Update existing
                              await collection.doc(existingBeer.id).update(beerData);
                            } else {
                              // Add new
                              await collection.add(beerData);
                            }

                            Navigator.pop(context);
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(existingBeer != null ? "SPEICHERN" : "HINZUFÜGEN"),
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox(); // Should not happen due to AuthGate

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('beers')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Fehler beim Laden", style: TextStyle(color: Colors.white)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
          }

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
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
                              color: const Color(0xFFFFC107).withOpacity(0.3 * _controller.value),
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
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final beer = ConsumedBeer.fromFirestore(docs[index]);
                return BeerListTile(
                  beer: beer,
                  animation: _controller,
                  onEdit: () => _showAddBeerDialog(existingBeer: beer),
                  onDelete: () async {
                     if (beer.id != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('beers')
                            .doc(beer.id)
                            .delete();
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
          label: const Text("BIER HINZUFÜGEN", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class ConsumedBeer {
  final String? id;
  final String name;
  final String country;
  final double percentage;
  final int rating;
  final DateTime date;

  ConsumedBeer({
    this.id,
    required this.name,
    required this.country,
    required this.percentage,
    required this.rating,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'country': country,
      'percentage': percentage,
      'rating': rating,
      'date': Timestamp.fromDate(date),
    };
  }

  factory ConsumedBeer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConsumedBeer(
      id: doc.id,
      name: data['name'] ?? '',
      country: data['country'] ?? '',
      percentage: (data['percentage'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0).toInt(),
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}

class BeerListTile extends StatefulWidget {
  final ConsumedBeer beer;
  final Animation<double> animation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BeerListTile({
    super.key,
    required this.beer,
    required this.animation,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<BeerListTile> createState() => _BeerListTileState();
}

class _BeerListTileState extends State<BeerListTile> {
  final List<Bubble> _bubbles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Generiere zufällige Blasen für diesen Balken
    for (int i = 0; i < 15; i++) {
      _bubbles.add(Bubble(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 4,
        speed: 0.3 + _random.nextDouble() * 0.7,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // 1. Bier Hintergrund (Gradient)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFFFFA000), // Dunkles Amber
                      Color(0xFFFFC107), // Gold
                    ],
                  ),
                ),
              ),
              
              // 2. Blasen Animation
              AnimatedBuilder(
                animation: widget.animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: BubblePainter(
                      bubbles: _bubbles,
                      animationValue: widget.animation.value,
                    ),
                    size: Size.infinite,
                  );
                },
              ),

              // 3. Inhalt
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Icon / Flagge (Platzhalter)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.beer.country.split(' ')[0], // Nimmt das Emoji
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Text Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.beer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                widget.beer.country.substring(3), // Ohne Emoji
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.star, size: 12, color: Colors.black.withOpacity(0.6)),
                              Text(
                                " ${widget.beer.rating}/10",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${widget.beer.date.day}.${widget.beer.date.month}.${widget.beer.date.year}",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Prozent Anzeige
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${widget.beer.percentage}%",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    
                    // Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black54),
                          onPressed: widget.onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class Bubble {
  final double x;
  final double y;
  final double size;
  final double speed;

  Bubble({required this.x, required this.y, required this.size, required this.speed});
}

class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double animationValue;

  BubblePainter({required this.bubbles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (var bubble in bubbles) {
      // Berechne Y-Position basierend auf Animation (Looping)
      // Wir addieren animationValue * speed zur ursprünglichen Y und nehmen Modulo 1
      // Da wir wollen, dass sie nach OBEN steigen, subtrahieren wir.
      double currentY = (bubble.y - (animationValue * bubble.speed)) % 1.0;
      if (currentY < 0) currentY += 1.0;

      // Zeichne Blase
      canvas.drawCircle(
        Offset(bubble.x * size.width, currentY * size.height),
        bubble.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
