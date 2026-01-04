// lib/pages/user_profile_setup_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';

class UserProfileSetupPage extends StatefulWidget {
  final BeerFirestoreService firestoreService;
  final VoidCallback onProfileComplete;

  const UserProfileSetupPage({
    super.key,
    required this.firestoreService,
    required this.onProfileComplete,
  });

  @override
  State<UserProfileSetupPage> createState() => _UserProfileSetupPageState();
}

class _UserProfileSetupPageState extends State<UserProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  
  String _selectedGender = 'male';
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Vorausfüllen mit Firebase Auth Daten falls vorhanden
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.displayName != null) {
      _nameController.text = currentUser.displayName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
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
        setState(() {
          _imageFile = File(pickedFile.path);
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

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String fileName = 'profile_$userId.jpg';
      
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(fileName);

      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _imageUrl = downloadUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profilbild hochgeladen!')),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Hochladen: $e')),
        );
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
      String userId = FirebaseAuth.instance.currentUser!.uid;
      
      // Bild URL (kann null sein - wird dann in Flutter generiert)
      String? finalImageUrl = _imageUrl;

      UserProfile profile = UserProfile(
        userId: userId,
        name: _nameController.text.trim(),
        weight: double.parse(_weightController.text.trim()),
        gender: _selectedGender,
        imageUrl: finalImageUrl,
        createdAt: DateTime.now(),
      );

      await widget.firestoreService.createUserProfile(profile);

      if (mounted) {
        // Modal schließen
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil erstellt!')),
        );
        widget.onProfileComplete();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  boxShadow: [BoxShadow(color: const Color(0xFFFFD700), blurRadius: 5)],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // AppBar-ähnliche Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'PROFIL KONFIGURATION 🍺',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(color: const Color(0xFF8D6E63).withOpacity(0.3)),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(24.0),
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
                        SizedBox(height: 20),
                        
                        // Willkommenstext
                        Text(
                          'WILLKOMMEN! 🍺',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(color: const Color(0xFFFFD700), blurRadius: 5)],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Initialisiere Benutzerparameter...',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                        
                        SizedBox(height: 40),
              
              // Profilbild
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFD700), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.2),
                              blurRadius: 15,
                            )
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
                          child: CircularProgressIndicator(color: const Color(0xFFFFD700)),
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
                          boxShadow: [BoxShadow(color: const Color(0xFFFFD700), blurRadius: 5)],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
              
              // Name
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Benutzername',
                  labelStyle: TextStyle(color: const Color(0xFFD4AF37)),
                  hintText: 'Wie möchtest du genannt werden?',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.person, color: const Color(0xFFFFD700)),
                  filled: true,
                  fillColor: const Color(0xFF12100E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF8D6E63)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF8D6E63).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFFFD700), width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte gib einen Namen ein';
                  }
                  if (value.trim().length < 2) {
                    return 'Name muss mindestens 2 Zeichen haben';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 20),
              
              // Gewicht
              TextFormField(
                controller: _weightController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Gewicht (kg)',
                  labelStyle: TextStyle(color: const Color(0xFFD4AF37)),
                  hintText: 'Für genaue Promille-Berechnung',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.monitor_weight, color: const Color(0xFFFFD700)),
                  suffixText: 'kg',
                  suffixStyle: TextStyle(color: const Color(0xFFFFD700)),
                  filled: true,
                  fillColor: const Color(0xFF12100E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF8D6E63)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF8D6E63).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFFFD700), width: 1.5),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte gib dein Gewicht ein';
                  }
                  double? weight = double.tryParse(value.trim());
                  if (weight == null || weight < 30 || weight > 300) {
                    return 'Bitte gib ein realistisches Gewicht ein (30-300 kg)';
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
                  border: Border.all(color: const Color(0xFF8D6E63).withOpacity(0.5)),
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
              
              SizedBox(height: 12),
              Text(
                'Wird für die Promille-Berechnung verwendet',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              
              SizedBox(height: 40),
              
              // Speichern Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _isUploadingImage ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700).withOpacity(0.1),
                    foregroundColor: const Color(0xFFFFD700),
                    side: const BorderSide(color: Color(0xFFFFD700), width: 1),
                    shadowColor: Colors.transparent,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: const Color(0xFFFFD700))
                      : Text(
                          'PROFIL ERSTELLEN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
              
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                  ),
                ),
              ),
            ],
          );
        },
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
          color: isSelected ? const Color(0xFFFFD700).withOpacity(0.1) : const Color(0xFF1F1B16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.grey[800]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.1), blurRadius: 5)] : [],
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