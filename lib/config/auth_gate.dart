import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:feierabendbierchen_flutter/services/auth_service.dart';
import '../pages/main_navigation.dart';
import '../pages/onboarding/onboarding_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isChecking = true;
  bool _isFirstLaunch = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final isFirst = await AuthService.isFirstLaunch();
    if (mounted) {
      setState(() {
        _isFirstLaunch = isFirst;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: const Color(0xFF12100E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFFFFD700),
              ),
              const SizedBox(height: 16),
              Text(
                'SYSTEM BOOT... 🍺',
                style: TextStyle(
                  color: const Color(0xFFFFD700),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Erster Start - zeige Onboarding
    if (_isFirstLaunch) {
      return const OnboardingPage();
    }

    // Normale App - StreamBuilder für Auth-Status
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        return FutureBuilder<bool>(
          future: AuthService.isGuestMode(),
          builder: (context, guestSnapshot) {
            final isLoggedIn = authSnapshot.data != null;
            final isGuestMode = guestSnapshot.data ?? false;

            return MyHomePage(
              isLoggedIn: isLoggedIn,
              isGuestMode: isGuestMode,
            );
          },
        );
      },
    );
  }
}
