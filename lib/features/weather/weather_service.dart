import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import 'weather_models.dart';

final weatherServiceProvider = Provider((ref) => WeatherService());

/// Fetches current conditions + 5-day forecast from OpenWeatherMap free tier.
class WeatherService {
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherData> fetchWeather({
    String city = CircleHub.defaultCity,
  }) async {
    final key = CircleHub.openWeatherKey;

    // cnt=8 → 8 × 3 h = 24 h of hourly-ish data for the graph
    final currentUri  = Uri.parse('$_baseUrl/weather?q=$city&appid=$key&units=imperial');
    final forecastUri = Uri.parse('$_baseUrl/forecast?q=$city&appid=$key&units=imperial&cnt=8');

    final responses = await Future.wait([
      http.get(currentUri),
      http.get(forecastUri),
    ]);

    if (responses[0].statusCode != 200) {
      throw Exception('Weather API error ${responses[0].statusCode}');
    }

    final current  = jsonDecode(responses[0].body) as Map<String, dynamic>;
    final foreJson = jsonDecode(responses[1].body) as Map<String, dynamic>;
    final items    = foreJson['list'] as List;

    // ── Hourly points for the graph (all 8 items) ────────────────────────────
    final hourly = <HourlyPoint>[];
    for (final item in items) {
      final dt   = DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
      final main = item['main'] as Map<String, dynamic>;
      hourly.add(HourlyPoint(
        time:  dt,
        tempF: (main['temp'] as num).toDouble(),
      ));
    }

    // ── One entry per unique calendar day (up to 4) ──────────────────────────
    final forecastDays = <ForecastDay>[];
    final seen = <String>{};
    for (final item in items) {
      final dt   = DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
      final key2 = '${dt.year}-${dt.month}-${dt.day}';
      if (seen.contains(key2)) continue;
      seen.add(key2);
      final main    = item['main'] as Map<String, dynamic>;
      final weather = (item['weather'] as List).first as Map<String, dynamic>;
      forecastDays.add(ForecastDay(
        date:     dt,
        minF:     (main['temp_min'] as num).toDouble(),
        maxF:     (main['temp_max'] as num).toDouble(),
        iconCode: weather['id'] as int,
      ));
      if (forecastDays.length >= 4) break;
    }

    return WeatherData.fromJson(current, forecastDays, hourly);
  }
}

/// Auto-refreshes every 30 minutes.
final weatherProvider = FutureProvider.autoDispose<WeatherData>((ref) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 30), link.close);
  return ref.read(weatherServiceProvider).fetchWeather();
});
