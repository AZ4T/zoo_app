// lib/providers/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocaleProvider extends ChangeNotifier {
  static const _boxName = 'settings';
  static const _key     = 'languageCode';

  Box? _settingsBox;
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  /// Call this once at startup to open the box and load the saved language.
  Future<void> init() async {
    _settingsBox = await Hive.openBox(_boxName);
    final code = _settingsBox!.get(_key, defaultValue: 'en') as String;
    _currentLocale = Locale(code);
    notifyListeners();
  }

  List<Locale> get supportedLocales => const [
        Locale('en'),
        Locale('ru'),
        Locale('kk'),
      ];

  /// Switch to a new locale and persist it.
  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;

    // Lazily open the box if init() hasn’t run yet:
    _settingsBox ??= await Hive.openBox(_boxName);

    await _settingsBox!.put(_key, locale.languageCode);
    notifyListeners();
  }

  /// Optional: if you ever want to clear the saved locale:
  Future<void> resetLocale() async {
    _settingsBox ??= await Hive.openBox(_boxName);
    await _settingsBox!.delete(_key);
    _currentLocale = const Locale('en');
    notifyListeners();
  }
}
