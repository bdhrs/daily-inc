import 'package:flutter/material.dart';

class ColorPalette {
  static const Color primaryBlue = Color.fromARGB(255, 29, 153, 255);
  static const Color darkBackground =
      Color(0xFF121212); // A very dark gray for main background
  static const Color cardBackground =
      Color(0xFF1E1E1E); // Slightly lighter dark gray for cards
  static const Color inputBackground =
      Color(0xFF2C2C2C); // Darker gray for input fields
  static const Color lightText = Colors.white;
  static const Color blackText =
      Colors.black; // New: Black text for light backgrounds
  static const Color secondaryText =
      Color(0xFFAAAAAA); // A lighter gray for secondary text
  static const Color warningOrange =
      Color.fromARGB(255, 196, 118, 0); // orange[200] - used for undone/error
  // New: distinct yellow for partially completed tasks
  static const Color partialYellow = Color(0xFFFFC107); // Amber 500
  static const Color onPartialYellow =
      Colors.black; // Ensure readable text/icons on yellow
  static const Color scrollbarThumb = Color(0xFF424242);
}
