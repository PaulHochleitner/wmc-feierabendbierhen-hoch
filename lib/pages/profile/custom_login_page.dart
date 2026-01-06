import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:feierabendbierchen_flutter/services/auth_service.dart';
import 'package:feierabendbierchen_flutter/l10n/app_localizations.dart';
import 'package:feierabendbierchen_flutter/services/beer_firestore_service.dart';
import 'package:feierabendbierchen_flutter/firebase_options.dart';

class CustomLoginPage extends StatefulWidget {
  final bool isRegisterMode;

  const CustomLoginPage({super.key, this.isRegisterMode = false});

  @override
  State<CustomLoginPage> createState() => _CustomLoginPageState();
}

class _CustomLoginPageState extends State<CustomLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Für Registrierung
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isRegisterMode = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.isRegisterMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        // Registrierung
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        // Name im User-Profil speichern (falls vorhanden)
        if (_nameController.text.trim().isNotEmpty && credential.user != null) {
          await credential.user!.updateDisplayName(_nameController.text.trim());
        }

        await AuthService.saveUserEmail(credential.user?.email);
        await AuthService.setGuestMode(false);

        // Zur Homepage navigieren - Profil-Setup wird automatisch als Modal angezeigt
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // Login
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        await AuthService.saveUserEmail(credential.user?.email);
        await AuthService.setGuestMode(false);

        // Prüfe ob Profil existiert
        try {
          final firestoreService = BeerFirestoreService();
          final existingProfile = await firestoreService.getUserProfile();

          if (mounted) {
            // Zur Homepage navigieren - Profil-Setup wird automatisch als Modal angezeigt
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } catch (profileError) {
          // Fehler beim Abrufen des Profils - trotzdem zur Homepage
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'weak-password':
          errorMsg = AppLocalizations.of(context).t('weak_password');
          break;
        case 'email-already-in-use':
          errorMsg = AppLocalizations.of(context).t('email_already_in_use');
          break;
        case 'user-not-found':
          errorMsg = AppLocalizations.of(context).t('user_not_found');
          break;
        case 'wrong-password':
          errorMsg = AppLocalizations.of(context).t('wrong_password');
          break;
        case 'invalid-email':
          errorMsg = AppLocalizations.of(context).t('invalid_email');
          break;
        default:
          errorMsg = 'Fehler: ${e.message ?? "Unbekannter Fehler"}';
      }
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // Detailliertere Fehlermeldung für besseres Debugging
        String errorMsg = 'Ein unerwarteter Fehler ist aufgetreten.';
        if (e is FirebaseAuthException) {
          errorMsg = 'Fehler: ${e.message ?? e.code}';
        } else {
          errorMsg = 'Fehler: ${e.toString()}';
        }
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Client-ID für alle Plattformen setzen
      String? clientId;
      if (kIsWeb) {
        // Web: Client-ID aus meta tag (wird automatisch gelesen, aber wir setzen sie trotzdem)
        clientId =
            '903834040298-pl04rrl645ov1pmk56vuvcn73b3uk28j.apps.googleusercontent.com';
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        clientId = DefaultFirebaseOptions.ios.iosClientId;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Android Client-ID aus google-services.json
        clientId =
            '903834040298-pl04rrl645ov1pmk56vuvcn73b3uk28j.apps.googleusercontent.com';
      }

      // Nur 'email' Scope verwenden, um People API zu vermeiden
      // Firebase Auth hat bereits alle benötigten Informationen
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        clientId: clientId,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User hat Sign-In abgebrochen
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await AuthService.saveUserEmail(FirebaseAuth.instance.currentUser?.email);
      await AuthService.setGuestMode(false);

      // Prüfe ob Profil existiert
      try {
        final firestoreService = BeerFirestoreService();
        final existingProfile = await firestoreService.getUserProfile();

        if (mounted) {
          // Zur Homepage navigieren - Profil-Setup wird automatisch als Modal angezeigt
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (profileError) {
        // Fehler beim Abrufen des Profils - trotzdem zur Homepage
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      setState(() {
        // Detailliertere Fehlermeldung
        String errorMsg = 'Google Sign-In fehlgeschlagen';
        if (e.toString().contains('People API')) {
          errorMsg =
              'Google Sign-In: People API ist nicht aktiviert. Bitte aktiviere sie in der Google Cloud Console oder verwende Email/Passwort Login.';
        } else {
          errorMsg = 'Google Sign-In fehlgeschlagen: ${e.toString()}';
        }
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF12100E), Color(0xFF251D18)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    height: constraints.maxHeight,
                    child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 24.0,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),

                        // Titel
                        Text(
                          _isRegisterMode
                              ? AppLocalizations.of(
                                  context,
                                ).t('register_button')
                              : AppLocalizations.of(context).t('login_button'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Name Feld (nur bei Registrierung)
                        if (_isRegisterMode)
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).t('name_label'),
                              labelStyle: const TextStyle(
                                color: Color(0xFF8D6E63),
                              ),
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Color(0xFFFFD700),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8D6E63),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: const Color(
                                    0xFF8D6E63,
                                  ).withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFD700),
                                  width: 2,
                                ),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (_isRegisterMode &&
                                  (value == null || value.trim().isEmpty)) {
                                return AppLocalizations.of(
                                  context,
                                ).t('please_enter_name');
                              }
                              return null;
                            },
                          ),
                        if (_isRegisterMode) const SizedBox(height: 20),

                        // Email Feld
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).t('login_email_label'),
                            labelStyle: const TextStyle(
                              color: Color(0xFF8D6E63),
                            ),
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Color(0xFFFFD700),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF8D6E63),
                              ),
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
                                width: 2,
                              ),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(
                                context,
                              ).t('please_enter_email');
                            }
                            if (!value.contains('@')) {
                              return AppLocalizations.of(
                                context,
                              ).t('invalid_email');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Passwort Feld
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            ).t('login_password_label'),
                            labelStyle: const TextStyle(
                              color: Color(0xFF8D6E63),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Color(0xFFFFD700),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xFFFFD700),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF8D6E63),
                              ),
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
                                width: 2,
                              ),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(
                                context,
                              ).t('please_enter_password');
                            }
                            if (_isRegisterMode && value.length < 6) {
                              return AppLocalizations.of(
                                context,
                              ).t('password_min_length');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // Fehler-Meldung
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Email/Passwort Button
                        Semantics(
                          button: true,
                          label: _isRegisterMode
                              ? AppLocalizations.of(
                                  context,
                                ).t('register_button')
                              : AppLocalizations.of(context).t('login_button'),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleEmailAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _isRegisterMode
                                        ? AppLocalizations.of(
                                            context,
                                          ).t('register_button')
                                        : AppLocalizations.of(
                                            context,
                                          ).t('login_button'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),

                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[700])),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'ODER',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[700])),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Google Sign-In Button
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: const Text(
                            'MIT GOOGLE ANMELDEN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD700),
                            side: const BorderSide(
                              color: Color(0xFFFFD700),
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Wechsel zwischen Login/Registrierung
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isRegisterMode
                                  ? 'Bereits ein Account?'
                                  : 'Noch kein Account?',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isRegisterMode = !_isRegisterMode;
                                  _errorMessage = null;
                                });
                              },
                              child: Text(
                                _isRegisterMode ? 'Anmelden' : 'Registrieren',
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Zurück Button
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'ZURÜCK',
                            style: TextStyle(
                              color: Color(0xFF8D6E63),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
