import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_inc/src/theme/app_palette.dart';
import 'package:daily_inc/src/theme/app_palette_registry.dart';

enum ThemeKey { classic, monk, sage }

extension ThemeKeyLabel on ThemeKey {
  String get label {
    switch (this) {
      case ThemeKey.classic:
        return 'Classic';
      case ThemeKey.monk:
        return 'Monk';
      case ThemeKey.sage:
        return 'Sage';
    }
  }
}

class ThemeController extends ValueNotifier<ThemeKey> {
  static const _prefKey = 'selected_theme';

  ThemeController._() : super(ThemeKey.classic);

  static final ThemeController instance = ThemeController._();

  Brightness _brightness = Brightness.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    value = ThemeKey.values.firstWhere(
      (k) => k.name == raw,
      orElse: () => ThemeKey.classic,
    );
  }

  Future<void> set(ThemeKey key) async {
    value = key;
    syncPalette(_brightness);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key.name);
  }

  (AppPalette, AppPalette) palettesFor(ThemeKey key) {
    switch (key) {
      case ThemeKey.classic:
        return (AppPalette.classicDark, AppPalette.classicLight);
      case ThemeKey.monk:
        return (AppPalette.monkDark, AppPalette.monkLight);
      case ThemeKey.sage:
        return (AppPalette.sageDark, AppPalette.sageLight);
    }
  }

  void syncPalette(Brightness brightness) {
    _brightness = brightness;
    final (dark, light) = palettesFor(value);
    AppPaletteRegistry.set(
      brightness == Brightness.dark ? dark : light,
    );
  }
}
