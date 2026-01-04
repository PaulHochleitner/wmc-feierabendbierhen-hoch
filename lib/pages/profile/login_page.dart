import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFFD700),
          surface: const Color(0xFF1F1B16),
        ),
        scaffoldBackgroundColor: const Color(0xFF12100E),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF8D6E63)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF8D6E63).withOpacity(0.5)),
          ),
        ),
      ),
      child: SignInScreen(
        providers: [
          EmailAuthProvider(),
          GoogleProvider(
            clientId:
                '903834040298-pl04rrl645ov1pmk56vuvcn73b3uk28j.apps.googleusercontent.com',
          ),
        ],
        actions: [
          AuthStateChangeAction<SignedIn>((context, state) {
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }
}