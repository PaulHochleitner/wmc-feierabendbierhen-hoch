import 'package:flutter/material.dart';
import 'package:feierabendbierchen_flutter/l10n/app_localizations.dart';
import 'package:feierabendbierchen_flutter/services/locale_service.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = LocaleService.locale.value.languageCode;
  }

  void _onSave() async {
    await LocaleService.setLocale(Locale(_selected));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('language_select_title')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
          tooltip: loc.t('cancel'),
        ),
        actions: [
          TextButton(
            onPressed: _onSave,
            child: Text(
              loc.t('save'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: Text(loc.t('language_name_de')),
            value: 'de',
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v ?? _selected),
          ),
          RadioListTile<String>(
            title: Text(loc.t('language_name_en')),
            value: 'en',
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v ?? _selected),
          ),
          RadioListTile<String>(
            title: Text(loc.t('language_name_hr')),
            value: 'hr',
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v ?? _selected),
          ),
        ],
      ),
    );
  }
}
