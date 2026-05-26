import 'package:flutter/material.dart';

class AppPalette {
  final Color primaryBlue;
  final Color darkBackground;
  final Color cardBackground;
  final Color inputBackground;
  final Color lightText;
  final Color blackText;
  final Color secondaryText;
  final Color warningOrange;
  final Color partialYellow;
  final Color onPartialYellow;
  final Color scrollbarThumb;

  const AppPalette({
    required this.primaryBlue,
    required this.darkBackground,
    required this.cardBackground,
    required this.inputBackground,
    required this.lightText,
    required this.blackText,
    required this.secondaryText,
    required this.warningOrange,
    required this.partialYellow,
    required this.onPartialYellow,
    required this.scrollbarThumb,
  });

  // ── Classic (blue) ───────────────────────────────────────────────────────

  static const AppPalette classicDark = AppPalette(
    primaryBlue: Color.fromARGB(255, 29, 153, 255),
    darkBackground: Color(0xFF121212),
    cardBackground: Color(0xFF1E1E1E),
    inputBackground: Color(0xFF2C2C2C),
    lightText: Colors.white,
    blackText: Colors.black,
    secondaryText: Color(0xFFAAAAAA),
    warningOrange: Color.fromARGB(255, 196, 118, 0),
    partialYellow: Color(0xFFFFC107),
    onPartialYellow: Colors.black,
    scrollbarThumb: Color(0xFF424242),
  );

  static const AppPalette classicLight = AppPalette(
    primaryBlue: Color(0xFF1565C0),
    darkBackground: Color(0xFFF5F5F5),
    cardBackground: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFEEEEEE),
    lightText: Color(0xFF212121),
    blackText: Colors.black,
    secondaryText: Color(0xFF757575),
    warningOrange: Color(0xFFE65100),
    partialYellow: Color(0xFFF9A825),
    onPartialYellow: Colors.black,
    scrollbarThumb: Color(0xFFBDBDBD),
  );

  // ── Monk (Kimbie warm) ───────────────────────────────────────────────────

  static const AppPalette monkDark = AppPalette(
    primaryBlue: Color(0xFFF79A32),
    darkBackground: Color(0xFF221A0F),
    cardBackground: Color(0xFF2F2418),
    inputBackground: Color(0xFF3A2C1B),
    lightText: Color(0xFFF8E5C0),
    blackText: Color(0xFF221A0F),
    secondaryText: Color(0xFFB59F7E),
    warningOrange: Color(0xFFE05C2A),
    partialYellow: Color(0xFFD4A83A),
    onPartialYellow: Color(0xFF221A0F),
    scrollbarThumb: Color(0xFF5B4A30),
  );

  static const AppPalette monkLight = AppPalette(
    primaryBlue: Color(0xFFB96C18),
    darkBackground: Color(0xFFFBF4E4),
    cardBackground: Color(0xFFF2E7CC),
    inputBackground: Color(0xFFE8DAB8),
    lightText: Color(0xFF2D2114),
    blackText: Color(0xFF2D2114),
    secondaryText: Color(0xFF7A6748),
    warningOrange: Color(0xFFBF4912),
    partialYellow: Color(0xFFB8860B),
    onPartialYellow: Colors.white,
    scrollbarThumb: Color(0xFFB5986A),
  );

  // ── Sage (sage / parchment) ──────────────────────────────────────────────

  static const AppPalette sageDark = AppPalette(
    primaryBlue: Color(0xFF8AA88A),
    darkBackground: Color(0xFF1A1F1B),
    cardBackground: Color(0xFF242A26),
    inputBackground: Color(0xFF2E3631),
    lightText: Color(0xFFE6E2D3),
    blackText: Color(0xFF1A1F1B),
    secondaryText: Color(0xFF94A099),
    warningOrange: Color(0xFFB87050),
    partialYellow: Color(0xFFA89050),
    onPartialYellow: Color(0xFF1A1F1B),
    scrollbarThumb: Color(0xFF4A5550),
  );

  static const AppPalette sageLight = AppPalette(
    primaryBlue: Color(0xFF4F7A55),
    darkBackground: Color(0xFFF2EFE3),
    cardBackground: Color(0xFFE7E2D0),
    inputBackground: Color(0xFFDCD7C2),
    lightText: Color(0xFF28301E),
    blackText: Color(0xFF28301E),
    secondaryText: Color(0xFF6B7264),
    warningOrange: Color(0xFF8B4A30),
    partialYellow: Color(0xFF7A7030),
    onPartialYellow: Colors.white,
    scrollbarThumb: Color(0xFFB0AA98),
  );
}
