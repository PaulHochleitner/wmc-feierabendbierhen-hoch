import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const _kLocaleCode = 'app_locale_code';
  static final ValueNotifier<Locale> locale = ValueNotifier(Locale('de'));

  static Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString(_kLocaleCode) ?? 'de';
    locale.value = Locale(code);
  }

  static Future<void> setLocale(Locale l) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLocaleCode, l.languageCode);
    locale.value = l;
  }
}
