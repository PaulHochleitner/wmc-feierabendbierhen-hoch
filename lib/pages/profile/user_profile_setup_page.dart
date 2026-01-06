// lib/pages/user_profile_setup_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:feierabendbierchen_flutter/services/cloudinary_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:path_provider/path_provider.dart';

class UserProfileSetupPage extends StatefulWidget {
  final BeerFirestoreService firestoreService;
  final VoidCallback onProfileComplete;
  final UserProfile?
  existingProfile; // Optional: vorhandenes Profil zum Bearbeiten

  const UserProfileSetupPage({
    super.key,
    required this.firestoreService,
    required this.onProfileComplete,
    this.existingProfile,
  });

  @override
  State<UserProfileSetupPage> createState() => _UserProfileSetupPageState();
}

class _UserProfileSetupPageState extends State<UserProfileSetupPage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String _selectedGender = 'male';
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _hasUnsavedChanges = false;
  bool _isSaved = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Vorausfüllen mit vorhandenem Profil oder Firebase Auth Daten
    if (widget.existingProfile != null) {
      // Vorhandenes Profil: alle Daten vorausfüllen
      _nameController.text = widget.existingProfile!.name;
      _weightController.text = widget.existingProfile!.weight.toStringAsFixed(
        1,
      );
      _heightController.text = widget.existingProfile!.height.toStringAsFixed(
        0,
      );
      _selectedGender = widget.existingProfile!.gender;
      _imageUrl = widget.existingProfile!.imageUrl;
    } else {
      // Neues Profil: nur Name aus Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.displayName != null) {
        _nameController.text = currentUser.displayName!;
      }
    }

    // Listener für Änderungen
    _nameController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges && !_isSaved) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.removeListener(_onFieldChanged);
    _weightController.removeListener(_onFieldChanged);
    _heightController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // Warnung beim Verlassen ohne Speichern
  Future<bool> _onWillPop() async {
    if (_isSaved || !_hasUnsavedChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1917),
        title: const Text(
          'Ungespeicherte Änderungen',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Du hast ungespeicherte Änderungen. Möchtest du wirklich verlassen?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Verlassen',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        // Kopiere die Datei in einen permanenten Speicherort
        final permanentFile = await _copyToPermanentLocation(pickedFile);

        setState(() {
          _imageFile = permanentFile;
        });

        // Bild direkt hochladen
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Bildes: $e')),
        );
      }
    }
  }

  Future<File> _copyToPermanentLocation(XFile sourceFile) async {
    try {
      // Nutze ein persistentes App-Verzeichnis, damit der Pfad stabil bleibt
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String ext = sourceFile.name.split('.').last;
      final String fileName =
          'profile_image_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final String permanentPath = '${appDir.path}/$fileName';

      // Kopiere die Datei
      final File permanentFile = await File(
        sourceFile.path,
      ).copy(permanentPath);
      return permanentFile;
    } catch (e) {
      // Falls Kopieren fehlschlägt, verwende die ursprüngliche Datei
      return File(sourceFile.path);
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Kein User eingeloggt. Bitte zuerst anmelden.');
      }

      // Stelle sicher, dass die Datei existiert (sonst Fehler)
      if (!await _imageFile!.exists()) {
        throw Exception('Lokale Bilddatei nicht gefunden.');
      }

      // Upload zu Cloudinary (komprimiert intern auf <= 500KB)
      final cloudinary = CloudinaryService();
      final uploadedUrl = await cloudinary.uploadProfileImage(
        _imageFile!,
        userId: currentUser.uid,
      );

      // Schreibe URL direkt in Firestore
      await widget.firestoreService.setUserImageUrl(uploadedUrl);

      setState(() {
        _imageUrl = uploadedUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profilbild erfolgreich hochgeladen!')),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Hochladen: $e')));
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profilbild auswählen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Hole User UID aus Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Kein User eingeloggt. Bitte zuerst anmelden.');
      }

      String userId = currentUser.uid;

      // 2. Parse Eingabedaten
      double weight = double.parse(_weightController.text.trim());
      double height = double.parse(_heightController.text.trim());
      String gender = _selectedGender;

      // 3. Speichere User-Daten (height, weight, gender) in Firestore
      // Collection: "users", Document ID: userId
      await widget.firestoreService.saveUserData(
        height: height,
        weight: weight,
        gender: gender,
      );

      // 4. Speichere vollständiges Profil (inkl. name, imageUrl)
      String? finalImageUrl = _imageUrl;
      UserProfile profile = UserProfile(
        userId: userId,
        name: _nameController.text.trim(),
        weight: weight,
        height: height,
        gender: gender,
        imageUrl: finalImageUrl,
        createdAt: DateTime.now(),
      );

      await widget.firestoreService.createUserProfile(profile);

      if (mounted) {
        setState(() {
          _isSaved = true;
          _hasUnsavedChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil erfolgreich erstellt!'),
            backgroundColor: Colors.green,
          ),
        );

        // Zurück navigieren
        Navigator.of(context).pop();
        widget.onProfileComplete();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String? _getDefaultAvatarUrl() {
    // Kein Default Avatar - nur wenn Bild hochgeladen wurde
    return _imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    // Bottom Navigation Bar Höhe
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF12100E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PROFIL KONFIGURATION 🍺',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Alle Felder sind erforderlich',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.0, 16.0, 24.0, bottomPadding),
          child: Theme(
            data: ThemeData.dark().copyWith(
              primaryColor: const Color(0xFFFFD700),
              colorScheme: ColorScheme.dark(primary: const Color(0xFFFFD700)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Info Box - Alle Felder erforderlich
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Alle Felder müssen ausgefüllt werden für vollständiges Tracking.',
                            style: TextStyle(
                              color: Colors.orange[200],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Willkommenstext
                  const Text(
                    'WILLKOMMEN! 🍺',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Color(0xFFFFD700), blurRadius: 5),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Initialisiere Benutzerparameter...',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Profilbild
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD700),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withOpacity(0.2),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: const Color(0xFF1F1B16),
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : _imageUrl != null
                                  ? NetworkImage(_imageUrl!)
                                  : null,
                              child: _imageFile == null && _imageUrl == null
                                  ? Icon(
                                      Icons.local_drink,
                                      size: 70,
                                      color: const Color(0xFFFFD700),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.black54,
                              child: CircularProgressIndicator(
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _showImageSourceDialog,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),
                  Text(
                    'Tippe auf das Bild zum Ändern',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),

                  SizedBox(height: 40),

                  // Name - ERFORDERLICH
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Benutzername *',
                      labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                      hintText: 'Wie möchtest du genannt werden?',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Color(0xFFFFD700),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF12100E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8D6E63)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF8D6E63).withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFFFD700),
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte gib einen Namen ein (ERFORDERLICH)';
                      }
                      if (value.trim().length < 2) {
                        return 'Name muss mindestens 2 Zeichen haben';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),

                  // Gewicht - ERFORDERLICH
                  TextFormField(
                    controller: _weightController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Gewicht (kg) *',
                      labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                      hintText: 'Für genaue Promille-Berechnung (ERFORDERLICH)',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(
                        Icons.monitor_weight,
                        color: Color(0xFFFFD700),
                      ),
                      suffixText: 'kg',
                      suffixStyle: const TextStyle(color: Color(0xFFFFD700)),
                      filled: true,
                      fillColor: const Color(0xFF12100E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8D6E63)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF8D6E63).withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFFFD700),
                          width: 1.5,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Gewicht ist ERFORDERLICH für vollständiges Tracking';
                      }
                      double? weight = double.tryParse(value.trim());
                      if (weight == null || weight < 30 || weight > 300) {
                        return 'Bitte gib ein realistisches Gewicht ein (30-300 kg)';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),

                  // Größe - ERFORDERLICH
                  TextFormField(
                    controller: _heightController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Größe (cm) *',
                      labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                      hintText: 'Für genaue Promille-Berechnung (ERFORDERLICH)',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(
                        Icons.height,
                        color: Color(0xFFFFD700),
                      ),
                      suffixText: 'cm',
                      suffixStyle: const TextStyle(color: Color(0xFFFFD700)),
                      filled: true,
                      fillColor: const Color(0xFF12100E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8D6E63)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: const Color(0xFF8D6E63).withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFFFD700),
                          width: 1.5,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Größe ist ERFORDERLICH für vollständiges Tracking';
                      }
                      double? height = double.tryParse(value.trim());
                      if (height == null || height < 100 || height > 250) {
                        return 'Bitte gib eine realistische Größe ein (100-250 cm)';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),

                  // Geschlecht
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF12100E),
                      border: Border.all(
                        color: const Color(0xFF8D6E63).withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Geschlecht',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildGenderOption(
                                'Männlich',
                                'male',
                                Icons.male,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderOption(
                                'Weiblich',
                                'female',
                                Icons.female,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'ERFORDERLICH für vollständiges Tracking und Promille-Berechnung',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[300],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Speichern Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isUploadingImage
                          ? null
                          : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'SPEICHERN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String label, String value, IconData icon) {
    bool isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD700).withOpacity(0.1)
              : const Color(0xFF1F1B16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.grey[800]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    blurRadius: 5,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? const Color(0xFFFFD700) : Colors.grey[600],
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFFFD700) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
