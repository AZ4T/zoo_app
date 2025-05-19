// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider with ChangeNotifier {
  bool isDark = false;
  int colorIndex = 0;

  final List<MaterialColor> colors = [
    Colors.deepPurple,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.teal,
    Colors.brown,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
  ];

  late Box settingsBox;

  /// Initialize from Hive; throws on failure.
  Future<void> init() async {
    try {
      settingsBox = await Hive.openBox('settings');
      isDark     = settingsBox.get('isDark', defaultValue: false) as bool;
      colorIndex = settingsBox.get('colorIndex', defaultValue: 0)   as int;
      notifyListeners();
    } catch (e, st) {
      debugPrint('ThemeProvider.init error: $e\n$st');
      throw Exception('Couldn’t load theme settings');
    }
  }

  ThemeData get themeData {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors[colorIndex],
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  /// Toggle dark/light mode and persist; throws on failure.
  Future<void> toggleTheme() async {
    try {
      isDark = !isDark;
      await settingsBox.put('isDark', isDark);
      notifyListeners();
    } catch (e, st) {
      debugPrint('toggleTheme error: $e\n$st');
      throw Exception('Couldn’t toggle theme');
    }
  }

  /// Change primary color index and persist; throws on failure.
  Future<void> changeColor(int index) async {
    try {
      colorIndex = index;
      await settingsBox.put('colorIndex', index);
      notifyListeners();
    } catch (e, st) {
      debugPrint('changeColor error: $e\n$st');
      throw Exception('Couldn’t change theme color');
    }
  }
}
