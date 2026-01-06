import 'package:flutter/material.dart';
import 'package:feierabendbierchen_flutter/services/auth_service.dart';
import 'package:feierabendbierchen_flutter/pages/profile/custom_login_page.dart';
import 'package:feierabendbierchen_flutter/l10n/app_localizations.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF12100E), // Deep Beer Black
              Color(0xFF251D18), // Dark Roasted Malt
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_drink,
                    size: 80,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 40),

                // Titel
                const Text(
                  'FEIERABEND BIERCHEN',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),

                // Untertitel
                Text(
                  'Willkommen beim Bier-Tracking System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[400],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 60),

                // Account erstellen Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Markiere ersten Start als erledigt
                      await AuthService.setFirstLaunchComplete();
                      await AuthService.setGuestMode(false);

                      // Navigiere zur Login/Registrierungs-Seite
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomLoginPage(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      AppLocalizations.of(context).t('register_button'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Oder Text
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[700])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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

                // Als Gast fortfahren Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      // Setze Gast-Modus und markiere ersten Start als erledigt
                      await AuthService.setFirstLaunchComplete();
                      await AuthService.setGuestMode(true);

                      // Navigiere zur Haupt-App
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
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
                    child: const Text(
                      'ALS GAST FORTFAHREN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Info Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Als Gast kannst du die App nutzen, aber deine Daten werden nicht gespeichert.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
