import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';

/// Renders a weather icon using the Erik Flowers Weather Icons font.
/// Font icons render crisply at any size and accept any Flutter color.
/// [size] is the icon size in logical pixels.
class WeatherIcon extends StatelessWidget {
  final int code;
  final double size;

  const WeatherIcon({super.key, required this.code, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDaytime = _isDaytime();
    final icon  = _iconData(code, isDaytime: isDaytime);
    final color = _iconColor(code);

    return Icon(icon, size: size, color: color);
  }

  static bool _isDaytime() {
    final h = DateTime.now().hour;
    return h >= 6 && h < 20;
  }

  static Color _iconColor(int code) {
    if (code == 800) return const Color(0xFFF5C842); // bright sun yellow
    if (code >= 801 && code <= 804) return const Color(0xFFB0B8CC); // cool grey cloud
    if (code >= 200 && code < 300) return const Color(0xFFAA88FF); // purple storm
    if (code >= 300 && code < 400) return const Color(0xFF6AB0F5); // soft blue drizzle
    if (code >= 500 && code < 600) return const Color(0xFF4A9EFF); // blue rain
    if (code >= 600 && code < 700) return const Color(0xFFCCE4FF); // icy white snow
    if (code >= 700 && code < 800) return const Color(0xFF8090A8); // grey fog
    return const Color(0xFFB0B8CC);
  }

  static IconData _iconData(int code, {bool isDaytime = true}) {
    // Clear
    if (code == 800) return isDaytime ? WeatherIcons.day_sunny : WeatherIcons.night_clear;

    // Clouds
    if (code == 801) return isDaytime ? WeatherIcons.day_cloudy : WeatherIcons.night_alt_cloudy;
    if (code == 802) return isDaytime ? WeatherIcons.day_cloudy_high : WeatherIcons.night_alt_cloudy_high;
    if (code == 803) return WeatherIcons.cloud;
    if (code == 804) return WeatherIcons.cloudy;

    // Thunderstorm
    if (code >= 200 && code < 210) return WeatherIcons.thunderstorm;
    if (code >= 210 && code < 230) return isDaytime ? WeatherIcons.day_thunderstorm : WeatherIcons.night_alt_thunderstorm;
    if (code >= 230 && code < 300) return WeatherIcons.storm_showers;

    // Drizzle
    if (code >= 300 && code < 400) return isDaytime ? WeatherIcons.day_sprinkle : WeatherIcons.night_alt_sprinkle;

    // Rain
    if (code == 500) return isDaytime ? WeatherIcons.day_rain : WeatherIcons.night_alt_rain;
    if (code == 501) return WeatherIcons.rain;
    if (code >= 502 && code <= 504) return WeatherIcons.rain_wind;
    if (code == 511) return WeatherIcons.sleet;
    if (code >= 520 && code <= 522) return WeatherIcons.showers;

    // Snow
    if (code == 600) return isDaytime ? WeatherIcons.day_snow : WeatherIcons.night_alt_snow;
    if (code == 601) return WeatherIcons.snow;
    if (code == 602) return WeatherIcons.snow_wind;
    if (code >= 611 && code <= 616) return WeatherIcons.sleet;
    if (code >= 620 && code <= 622) return WeatherIcons.snow;

    // Atmosphere
    if (code == 701 || code == 741) return isDaytime ? WeatherIcons.day_fog : WeatherIcons.night_fog;
    if (code == 711) return WeatherIcons.smoke;
    if (code == 721) return isDaytime ? WeatherIcons.day_haze : WeatherIcons.dust;
    if (code == 731 || code == 761 || code == 762) return WeatherIcons.dust;
    if (code == 751) return WeatherIcons.sandstorm;
    if (code == 771) return WeatherIcons.strong_wind;
    if (code == 781) return WeatherIcons.tornado;

    // Extreme
    if (code == 901) return WeatherIcons.hurricane;
    if (code == 902) return WeatherIcons.hurricane;

    return WeatherIcons.cloudy;
  }
}
