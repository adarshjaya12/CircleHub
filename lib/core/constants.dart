import 'package:flutter/material.dart';

/// Single source of truth for all Circle Hub dimensions, colors, and config.
class CircleHub {
  // ── Display ──────────────────────────────────────────────────────────────
  /// Physical display pixel dimensions (1080×1080 square).
  static const double displaySize = 1080.0;
  static const double radius = displaySize / 2; // 540px

  /// Safe zone: content within 85% of radius avoids edge-clipping on round glass.
  static const double safeRadius = radius * 0.85;
  static const double safeEdgePad = radius - safeRadius; // ~81px each side

  // ── Colors ────────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF060608);
  static const Color surface        = Color(0xFF0F0F14);
  static const Color surfaceHigh    = Color(0xFF1A1A22);

  // Accent — warm gold for clock hands, alarm, highlights
  static const Color accent         = Color(0xFFF5A623);
  static const Color accentBlue     = Color(0xFF4A9EFF);
  static const Color accentGreen    = Color(0xFF4ADE80);

  // Text
  static const Color textPrimary    = Color(0xFFE8E8EC);
  static const Color textSecondary  = Color(0xFF7A7A8A);
  static const Color textDim        = Color(0xFF3A3A4A);

  // Clock hands
  static const Color handHour       = Color(0xFFE8E8EC);
  static const Color handMinute     = Color(0xFFE8E8EC);
  static const Color handSecond     = Color(0xFFE63946);

  // Tick marks
  static const Color tickMajor      = Color(0xFF5A5A6A);
  static const Color tickMinor      = Color(0xFF2A2A38);

  // Alarm states
  static const Color alarmRinging   = Color(0xFFE63946);
  static const Color alarmSnoozed   = Color(0xFFF5A623);
  static const Color alarmSet       = Color(0xFF4A9EFF);

  // ── API Keys — injected at build time via --dart-define-from-file=local.env
  // Never hardcode keys here. Run with: flutter run --dart-define-from-file=local.env
  static const String openWeatherKey =
      String.fromEnvironment('OPENWEATHER_KEY', defaultValue: '');
  static const String newsApiKey =
      String.fromEnvironment('NEWSAPI_KEY', defaultValue: '');

  /// Default city for weather — can be overridden in settings.
  static const String defaultCity    = 'Chicago';

  // ── GPIO ─────────────────────────────────────────────────────────────────
  static const int bellGpioPin      = 17; // BCM numbering
  static const int pulseOnMs        = 50; // 50ms ON
  static const int pulseOffMs       = 50; // 50ms OFF → 10Hz

  // ── Alarm ─────────────────────────────────────────────────────────────────
  static const int snoozeDurationMinutes = 5;
  static const int maxRingMinutes        = 10; // auto-dismiss after 10 min
}
