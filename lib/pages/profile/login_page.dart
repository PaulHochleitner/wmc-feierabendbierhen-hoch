import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
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
    );
  }
}