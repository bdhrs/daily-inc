import 'package:daily_inc/src/theme/app_palette.dart';

class AppPaletteRegistry {
  static AppPalette _current = AppPalette.classicDark;

  static AppPalette get current => _current;

  static void set(AppPalette palette) {
    _current = palette;
  }
}
