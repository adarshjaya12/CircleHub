import 'package:flutter/material.dart';

/// Parsed weather data from OpenWeatherMap (imperial units — °F, mph).
class WeatherData {
  final String city;
  final double tempF;
  final double feelsLikeF;
  final int humidity;
  final double windMph;
  final String condition;      // e.g. "Clear", "Rain"
  final String description;    // e.g. "clear sky"
  final int iconCode;          // OWM icon id, e.g. 800 = clear
  final List<ForecastDay> forecast;
  final DateTime sunset;
  final List<HourlyPoint> hourly; // next 24 h in 3-hr steps

  const WeatherData({
    required this.city,
    required this.tempF,
    required this.feelsLikeF,
    required this.humidity,
    required this.windMph,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.forecast,
    required this.sunset,
    required this.hourly,
  });

  factory WeatherData.fromJson(
      Map<String, dynamic> json,
      List<ForecastDay> forecast,
      List<HourlyPoint> hourly) {
    final main    = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind    = json['wind'] as Map<String, dynamic>;
    final sys     = json['sys'] as Map<String, dynamic>;
    return WeatherData(
      city:        json['name'] as String,
      tempF:       (main['temp'] as num).toDouble(),
      feelsLikeF:  (main['feels_like'] as num).toDouble(),
      humidity:    main['humidity'] as int,
      windMph:     (wind['speed'] as num).toDouble(),
      condition:   weather['main'] as String,
      description: weather['description'] as String,
      iconCode:    weather['id'] as int,
      forecast:    forecast,
      sunset:      DateTime.fromMillisecondsSinceEpoch((sys['sunset'] as int) * 1000),
      hourly:      hourly,
    );
  }
}

class ForecastDay {
  final DateTime date;
  final double minF;
  final double maxF;
  final int iconCode;

  const ForecastDay({
    required this.date,
    required this.minF,
    required this.maxF,
    required this.iconCode,
  });
}

class HourlyPoint {
  final DateTime time;
  final double tempF;
  const HourlyPoint({required this.time, required this.tempF});
}

/// Maps OWM condition id ranges to a single emoji icon.
String weatherEmoji(int id) {
  if (id == 800) return '☀️';
  if (id >= 801 && id <= 804) return '⛅';
  if (id >= 700 && id < 800) return '🌫️';
  if (id >= 600 && id < 700) return '❄️';
  if (id >= 500 && id < 600) return '🌧️';
  if (id >= 300 && id < 400) return '🌦️';
  if (id >= 200 && id < 300) return '⛈️';
  return '🌡️';
}

/// Accent color for the condition blob in the Visual style.
Color conditionColor(int id) {
  if (id == 800) return const Color(0xFFF5A623);          // clear — amber
  if (id >= 801 && id <= 802) return const Color(0xFF7A9EC0); // few/scattered clouds
  if (id >= 803 && id <= 804) return const Color(0xFF6B6B7A); // overcast
  if (id >= 700 && id < 800) return const Color(0xFF8A9BA8);  // fog
  if (id >= 600 && id < 700) return const Color(0xFFB0CDE0);  // snow
  if (id >= 500 && id < 600) return const Color(0xFF4A7FA5);  // rain
  if (id >= 300 && id < 400) return const Color(0xFF5A8FAF);  // drizzle
  if (id >= 200 && id < 300) return const Color(0xFF3A3A5C);  // storm
  return const Color(0xFF6B6B7A);
}
