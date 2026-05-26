import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:daily_inc/src/theme/app_palette.dart';

class AppTheme {
  static ThemeData build(AppPalette p, {required Brightness brightness}) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: p.primaryBlue,
        onPrimary: p.lightText,
        secondary: p.primaryBlue,
        onSecondary: p.lightText,
        surface: p.cardBackground,
        onSurface: p.lightText,
        error: p.warningOrange,
        onError: p.lightText,
      ),
      scaffoldBackgroundColor: p.darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: p.darkBackground,
        foregroundColor: p.lightText,
        elevation: 0,
      ),
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme.copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(color: p.lightText),
          displayMedium: base.textTheme.displayMedium?.copyWith(color: p.lightText),
          displaySmall: base.textTheme.displaySmall?.copyWith(color: p.lightText),
          headlineLarge: base.textTheme.headlineLarge?.copyWith(color: p.lightText),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(color: p.lightText),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(color: p.lightText),
          titleLarge: base.textTheme.titleLarge?.copyWith(color: p.lightText),
          titleMedium: base.textTheme.titleMedium?.copyWith(color: p.primaryBlue),
          titleSmall: base.textTheme.titleSmall?.copyWith(color: p.lightText),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(color: p.lightText),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(color: p.lightText),
          bodySmall: base.textTheme.bodySmall?.copyWith(color: p.secondaryText),
          labelLarge: base.textTheme.labelLarge?.copyWith(color: p.lightText),
          labelMedium: base.textTheme.labelMedium?.copyWith(color: p.secondaryText),
          labelSmall: base.textTheme.labelSmall?.copyWith(color: p.secondaryText),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.cardBackground,
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primaryBlue,
          foregroundColor: p.lightText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.primaryBlue),
      ),
      iconTheme: IconThemeData(color: p.lightText),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: p.primaryBlue, width: 2),
        ),
        labelStyle: TextStyle(color: p.secondaryText),
        hintStyle: TextStyle(color: p.secondaryText),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.cardBackground,
        contentTextStyle: TextStyle(color: p.lightText),
        actionTextColor: p.primaryBlue,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.cardBackground,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(color: p.lightText),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(color: p.lightText),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primaryBlue;
          return p.secondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.primaryBlue.withAlpha(128);
          }
          return p.secondaryText.withAlpha(128);
        }),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: p.lightText,
        collapsedIconColor: p.lightText,
        textColor: p.lightText,
        collapsedTextColor: p.lightText,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.cardBackground,
        hourMinuteTextStyle: TextStyle(color: p.lightText, fontSize: 36),
        hourMinuteColor: p.inputBackground,
        hourMinuteTextColor: p.lightText,
        dialHandColor: p.primaryBlue,
        dialBackgroundColor: p.inputBackground,
        dialTextColor: p.lightText,
        entryModeIconColor: p.primaryBlue,
        dayPeriodTextStyle: TextStyle(color: p.lightText),
        dayPeriodColor: p.inputBackground,
        dayPeriodTextColor: p.lightText,
        dayPeriodBorderSide: BorderSide(color: p.primaryBlue),
        helpTextStyle: TextStyle(color: p.lightText),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: p.lightText),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: p.primaryBlue),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(p.scrollbarThumb),
      ),
    );
  }

  static ThemeData get darkTheme =>
      build(AppPalette.classicDark, brightness: Brightness.dark);
}
