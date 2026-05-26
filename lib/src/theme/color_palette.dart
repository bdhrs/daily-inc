import 'package:flutter/material.dart';
import 'package:daily_inc/src/theme/app_palette_registry.dart';

class ColorPalette {
  static Color get primaryBlue => AppPaletteRegistry.current.primaryBlue;
  static Color get darkBackground => AppPaletteRegistry.current.darkBackground;
  static Color get cardBackground => AppPaletteRegistry.current.cardBackground;
  static Color get inputBackground => AppPaletteRegistry.current.inputBackground;
  static Color get lightText => AppPaletteRegistry.current.lightText;
  static Color get blackText => AppPaletteRegistry.current.blackText;
  static Color get secondaryText => AppPaletteRegistry.current.secondaryText;
  static Color get warningOrange => AppPaletteRegistry.current.warningOrange;
  static Color get partialYellow => AppPaletteRegistry.current.partialYellow;
  static Color get onPartialYellow => AppPaletteRegistry.current.onPartialYellow;
  static Color get scrollbarThumb => AppPaletteRegistry.current.scrollbarThumb;
}
