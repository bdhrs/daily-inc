import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daily_inc/src/theme/color_palette.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    return baseTheme.copyWith(
      // Define the color scheme
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: ColorPalette.primaryBlue,
        onPrimary: ColorPalette.lightText,
        secondary:
            ColorPalette.primaryBlue, // Using primary blue as secondary accent
        onSecondary: ColorPalette.lightText,
        surface: ColorPalette.cardBackground, // For cards and elevated surfaces
        onSurface: ColorPalette.lightText,

        error: ColorPalette.errorRed,
        onError: ColorPalette.lightText,
      ),
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorPalette.darkBackground,
        foregroundColor: ColorPalette.lightText,
        elevation: 0,
      ),
      // Text theme with Google Fonts
      textTheme: GoogleFonts.interTextTheme(
        baseTheme.textTheme.copyWith(
          displayLarge: baseTheme.textTheme.displayLarge
              ?.copyWith(color: ColorPalette.lightText),
          displayMedium: baseTheme.textTheme.displayMedium
              ?.copyWith(color: ColorPalette.lightText),
          displaySmall: baseTheme.textTheme.displaySmall
              ?.copyWith(color: ColorPalette.lightText),
          headlineLarge: baseTheme.textTheme.headlineLarge
              ?.copyWith(color: ColorPalette.lightText),
          headlineMedium: baseTheme.textTheme.headlineMedium
              ?.copyWith(color: ColorPalette.lightText),
          headlineSmall: baseTheme.textTheme.headlineSmall
              ?.copyWith(color: ColorPalette.primaryBlue), // App title
          titleLarge: baseTheme.textTheme.titleLarge
              ?.copyWith(color: ColorPalette.lightText),
          titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
              color: ColorPalette.primaryBlue), // Headings in add/edit
          titleSmall: baseTheme.textTheme.titleSmall
              ?.copyWith(color: ColorPalette.lightText),
          bodyLarge: baseTheme.textTheme.bodyLarge
              ?.copyWith(color: ColorPalette.lightText),
          bodyMedium: baseTheme.textTheme.bodyMedium
              ?.copyWith(color: ColorPalette.lightText),
          bodySmall: baseTheme.textTheme.bodySmall
              ?.copyWith(color: ColorPalette.secondaryText),
          labelLarge: baseTheme.textTheme.labelLarge
              ?.copyWith(color: ColorPalette.lightText),
          labelMedium: baseTheme.textTheme.labelMedium
              ?.copyWith(color: ColorPalette.secondaryText),
          labelSmall: baseTheme.textTheme.labelSmall
              ?.copyWith(color: ColorPalette.secondaryText),
        ),
      ),
      // Card theme
      cardTheme: const CardTheme(
        color: ColorPalette.cardBackground,
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        elevation: 2,
      ),
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primaryBlue, // Timer buttons
          foregroundColor: ColorPalette.lightText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorPalette.primaryBlue,
        ),
      ),
      iconTheme: const IconThemeData(
        color: ColorPalette.lightText,
      ),
      // Input decoration theme for text fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            ColorPalette.inputBackground, // Dark background for input fields
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none, // No border for filled fields
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: ColorPalette.primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: ColorPalette.secondaryText),
        hintStyle: const TextStyle(color: ColorPalette.secondaryText),
      ),
      // SnackBar theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor:
            ColorPalette.cardBackground, // Use card background for snackbar
        contentTextStyle: TextStyle(color: ColorPalette.lightText),
      ),
      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: ColorPalette.cardBackground,
        titleTextStyle: baseTheme.textTheme.titleLarge
            ?.copyWith(color: ColorPalette.lightText),
        contentTextStyle: baseTheme.textTheme.bodyMedium
            ?.copyWith(color: ColorPalette.lightText),
      ),
      // SwitchListTile theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorPalette.primaryBlue;
          }
          return ColorPalette.secondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorPalette.primaryBlue.withValues(alpha: 0.5);
          }
          return ColorPalette.secondaryText.withValues(alpha: 0.5);
        }),
      ),
      // ExpansionTile theme
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: ColorPalette.lightText,
        collapsedIconColor: ColorPalette.lightText,
        textColor: ColorPalette.lightText,
        collapsedTextColor: ColorPalette.lightText,
      ),
    );
  }
}
