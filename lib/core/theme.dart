import 'package:flutter/material.dart';
import 'constants.dart';

class CircleHubTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: CircleHub.background,
    colorScheme: const ColorScheme.dark(
      primary: CircleHub.accent,
      secondary: CircleHub.accentBlue,
      surface: CircleHub.surface,
      onSurface: CircleHub.textPrimary,
    ),
    textTheme: const TextTheme(
      // Clock digits, large numbers
      displayLarge: TextStyle(
        color: CircleHub.textPrimary,
        fontSize: 96,
        fontWeight: FontWeight.w100,
        letterSpacing: -4,
      ),
      // Section headers (Weather, News page titles)
      headlineMedium: TextStyle(
        color: CircleHub.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w200,
        letterSpacing: 4,
      ),
      // Body content
      bodyLarge: TextStyle(
        color: CircleHub.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w300,
      ),
      bodyMedium: TextStyle(
        color: CircleHub.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      // Labels, captions
      labelSmall: TextStyle(
        color: CircleHub.textDim,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
    ),
    useMaterial3: true,
  );
}
