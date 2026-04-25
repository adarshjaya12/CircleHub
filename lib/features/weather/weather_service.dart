import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/device_service.dart';
import 'weather_models.dart';

final weatherServiceProvider = Provider((ref) {
  final deviceService = ref.read(deviceServiceProvider);
  return WeatherService(deviceService);
});

/// Fetches weather data through the CircleHub API proxy.
/// The OWM key never touches the device — it lives on the server.
class WeatherService {
  final DeviceService _deviceService;
  WeatherService(this._deviceService);

  static const _base = DeviceService.apiBase;

  Future<WeatherData> fetchWeather({String? city}) async {
    final token = await _deviceService.getToken();
    final headers = {'Authorization': 'Bearer $token'};

    // Use provided city, or fetch the device's configured location from the API
    final resolvedCity = city ?? await _deviceService.fetchLocation(token);
    final cityEncoded = Uri.encodeComponent(resolvedCity);

    final responses = await Future.wait([
      http.get(Uri.parse('$_base/api/weather/current?city=$cityEncoded'),
          headers: headers),
      http.get(Uri.parse('$_base/api/weather/forecast?city=$cityEncoded&count=8'),
          headers: headers),
    ]);

    if (responses[0].statusCode != 200) {
      throw Exception('Weather API error ${responses[0].statusCode}: ${responses[0].body}');
    }

    final current  = jsonDecode(responses[0].body) as Map<String, dynamic>;
    final foreJson = jsonDecode(responses[1].body) as Map<String, dynamic>;
    final items    = foreJson['list'] as List;

    // ── Hourly points ────────────────────────────────────────────────────────
    final hourly = <HourlyPoint>[];
    for (final item in items) {
      final dt   = DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
      final main = item['main'] as Map<String, dynamic>;
      hourly.add(HourlyPoint(time: dt, tempF: (main['temp'] as num).toDouble()));
    }

    // ── Forecast days (up to 4) ───────────────────────────────────────────────
    final forecastDays = <ForecastDay>[];
    final seen = <String>{};
    for (final item in items) {
      final dt   = DateTime.fromMillisecondsSinceEpoch((item['dt'] as int) * 1000);
      final key  = '${dt.year}-${dt.month}-${dt.day}';
      if (seen.contains(key)) continue;
      seen.add(key);
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
