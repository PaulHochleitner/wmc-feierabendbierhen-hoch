import 'package:flutter/material.dart';
import 'package:feierabendbierchen_flutter/l10n/app_localizations.dart';
import 'package:feierabendbierchen_flutter/services/locale_service.dart';
import 'package:feierabendbierchen_flutter/pages/settings/language_selection_page.dart';
import 'package:feierabendbierchen_flutter/services/location_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final current = LocaleService.locale.value.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('settings_title')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).t('settings'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Sprache Section
              Text(
                AppLocalizations.of(context).t('language'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<Locale>(
                valueListenable: LocaleService.locale,
                builder: (context, loc, _) {
                  final currentCode = loc.languageCode;
                  String currentLabel;
                  switch (currentCode) {
                    case 'de':
                      currentLabel = AppLocalizations.of(
                        context,
                      ).t('language_name_de');
                      break;
                    case 'hr':
                      currentLabel = AppLocalizations.of(
                        context,
                      ).t('language_name_hr');
                      break;
                    default:
                      currentLabel = AppLocalizations.of(
                        context,
                      ).t('language_name_en');
                  }
                  return ListTile(
                    title: Text(AppLocalizations.of(context).t('language')),
                    subtitle: Text(currentLabel),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LanguageSelectionPage(),
                        ),
                      );
                      if (saved == true &&
                          ScaffoldMessenger.maybeOf(context) != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              ).t('language_changed'),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // Standort Einstellungen
              Text(
                "BERECHTIGUNGEN",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text("App-Berechtigungen"),
                subtitle: const Text("Zugriff erlauben/verbieten"),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => LocationService().openSettings(),
              ),
              ListTile(
                title: const Text("GPS aktivieren"),
                subtitle: const Text("System-Standortdienste öffnen"),
                trailing: const Icon(Icons.location_on),
                onTap: () => LocationService().openLocationSettings(),
              ),
              const SizedBox(height: 24),

              // Accessibility tip
              Text(
                '🔧 ${AppLocalizations.of(context).t('settings_title')}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
