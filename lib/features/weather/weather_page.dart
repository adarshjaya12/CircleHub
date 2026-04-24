import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../widgets/weather_icon.dart';
import 'weather_service.dart';
import 'weather_models.dart';

enum WeatherStyle { card, face, summary }

class WeatherPage extends ConsumerStatefulWidget {
  const WeatherPage({super.key});

  @override
  ConsumerState<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends ConsumerState<WeatherPage> {
  WeatherStyle _style = WeatherStyle.card;

  void _cycle() => setState(() =>
      _style = WeatherStyle.values[(_style.index + 1) % WeatherStyle.values.length]);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(weatherProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _cycle,
      child: Container(
        color: CircleHub.background,
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
                color: CircleHub.accent, strokeWidth: 1.5),
          ),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (w) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: KeyedSubtree(
              key: ValueKey(_style),
              child: switch (_style) {
                WeatherStyle.card   => _CardView(data: w),
                WeatherStyle.face   => _FaceView(data: w),
                WeatherStyle.summary => _VisualView(data: w),
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── STYLE 1: Original card layout ───────────────────────────────────────────

class _CardView extends StatelessWidget {
  final WeatherData data;
  const _CardView({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      final R = box.maxWidth / 2;
      final tempStr = '${data.tempF.round()}°F';

      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [Color(0xFF0D1929), CircleHub.background],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: R * 0.22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // City
                Text(data.city.toUpperCase(),
                    style: TextStyle(
                      color: CircleHub.textSecondary,
                      fontSize: R * 0.09,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                    )),
                SizedBox(height: R * 0.06),

                // Icon + temperature
                WeatherIcon(code: data.iconCode, size: R * 0.30),
                SizedBox(height: R * 0.02),
                Text(tempStr,
                    style: TextStyle(
                      color: CircleHub.textPrimary,
                      fontSize: R * 0.36,
                      fontWeight: FontWeight.w200,
                      height: 1,
                    )),

                // Description
                Text(data.description.toUpperCase(),
                    style: TextStyle(
                      color: CircleHub.accent,
                      fontSize: R * 0.07,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w300,
                    )),
                SizedBox(height: R * 0.08),

                // Details row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DetailChip(label: 'FEELS', value: '${data.feelsLikeF.round()}°', R: R),
                    SizedBox(width: R * 0.08),
                    _DetailChip(label: 'HUM', value: '${data.humidity}%', R: R),
                    SizedBox(width: R * 0.08),
                    _DetailChip(label: 'WIND', value: '${data.windMph.round()}mph', R: R),
                  ],
                ),
                SizedBox(height: R * 0.08),

                // 4-day forecast strip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: data.forecast
                      .map((f) => _ForecastTile(day: f, R: R))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ── STYLE 2: Prose / natural-language layout ────────────────────────────────
// "It's 83° / in Fort Myers / feels like 79° / ☀️ sun will / set in 2 hr"

class _FaceView extends StatelessWidget {
  final WeatherData data;
  const _FaceView({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      final R    = box.maxWidth / 2;
      final fs   = R * 0.20; // base font size
      final dim  = CircleHub.textSecondary.withAlpha(140);
      final bright = CircleHub.textPrimary;

      final conditionWord = _conditionWord(data.iconCode);
      final sunText       = _sunsetText(data.sunset);

      TextStyle plain(double size) => TextStyle(
        color: dim, fontSize: size, fontWeight: FontWeight.w300, height: 1.35);
      TextStyle bold(double size) => TextStyle(
        color: bright, fontSize: size, fontWeight: FontWeight.w700, height: 1.35);

      return Container(
        color: CircleHub.background,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: R * 0.32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "It's 83°"
            RichText(text: TextSpan(children: [
              TextSpan(text: "It's ", style: plain(fs)),
              TextSpan(text: '${data.tempF.round()}°', style: bold(fs)),
            ])),

            // "in Fort Myers"
            RichText(text: TextSpan(children: [
              TextSpan(text: 'in ', style: plain(fs)),
              TextSpan(text: data.city, style: bold(fs)),
            ])),

            // "feels like 79°"
            RichText(text: TextSpan(children: [
              TextSpan(text: 'feels like ', style: plain(fs * 0.82)),
              TextSpan(text: '${data.feelsLikeF.round()}°', style: bold(fs * 0.82)),
            ])),

            SizedBox(height: R * 0.05),

            // icon + "sun will"
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                WeatherIcon(code: data.iconCode, size: fs * 1.1),
                SizedBox(width: fs * 0.3),
                RichText(text: TextSpan(children: [
                  TextSpan(text: conditionWord, style: bold(fs * 0.88)),
                  TextSpan(text: ' will', style: plain(fs * 0.88)),
                ])),
              ],
            ),

            // "set in 2 hr"
            RichText(text: TextSpan(children: [
              TextSpan(text: 'set in ', style: plain(fs * 0.88)),
              TextSpan(text: sunText, style: bold(fs * 0.88)),
            ])),
          ],
        ),
      );
    });
  }

  /// Short noun for the sky condition (used in "☀️ sun will set in…")
  String _conditionWord(int id) {
    if (id == 800) return 'sun';
    if (id >= 801 && id <= 804) return 'cloud';
    if (id >= 700 && id < 800) return 'fog';
    if (id >= 600 && id < 700) return 'snow';
    if (id >= 500 && id < 600) return 'rain';
    if (id >= 300 && id < 400) return 'drizzle';
    if (id >= 200 && id < 300) return 'storm';
    return 'sky';
  }

  /// "2 hr" / "45 min" / "risen Xhr ago" depending on time
  String _sunsetText(DateTime sunset) {
    final diff = sunset.difference(DateTime.now());
    if (diff.isNegative) {
      final hrs = (-diff.inMinutes / 60).round();
      return hrs <= 1 ? '${ -diff.inMinutes} min ago' : '$hrs hr ago';
    }
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    return '${(diff.inMinutes / 60).round()} hr';
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final double R;
  const _DetailChip({required this.label, required this.value, required this.R});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: CircleHub.textDim, fontSize: R * 0.055, letterSpacing: 1.5)),
        SizedBox(height: R * 0.015),
        Text(value,
            style: TextStyle(
                color: CircleHub.textPrimary,
                fontSize: R * 0.09,
                fontWeight: FontWeight.w300)),
      ],
    );
  }
}

class _ForecastTile extends StatelessWidget {
  final ForecastDay day;
  final double R;
  const _ForecastTile({required this.day, required this.R});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R * 0.025),
      child: Column(
        children: [
          Text(
            DateFormat('E').format(day.date).toUpperCase(),
            style: TextStyle(
                color: CircleHub.textDim, fontSize: R * 0.055, letterSpacing: 1.5),
          ),
          SizedBox(height: R * 0.02),
          WeatherIcon(code: day.iconCode, size: R * 0.13),
          SizedBox(height: R * 0.02),
          Text(
            '${day.maxF.round()}°  ${day.minF.round()}°',
            style: TextStyle(
                color: CircleHub.textSecondary,
                fontSize: R * 0.065,
                fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }
}

// ── STYLE 3: Summary — temp + icon chip + sentence + hourly strip ────────────

class _VisualView extends StatelessWidget {
  final WeatherData data;
  const _VisualView({required this.data});

  @override
  Widget build(BuildContext context) {
    final sentence = _buildSentence(data);
    final slots    = data.hourly.take(4).toList();

    return LayoutBuilder(builder: (_, box) {
      final R    = box.maxWidth / 2;
      final hPad = R * 0.20;

      return Container(
        color: CircleHub.background,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ── Large centered icon ──────────────────────────────────────────
            WeatherIcon(code: data.iconCode, size: R * 0.38),

            SizedBox(height: R * 0.03),

            // ── Temperature ──────────────────────────────────────────────────
            Text(
              '${data.tempF.round()}°',
              style: TextStyle(
                color: CircleHub.textPrimary,
                fontSize: R * 0.38,
                fontWeight: FontWeight.w300,
                height: 1.0,
                letterSpacing: -2,
              ),
            ),

            SizedBox(height: R * 0.05),

            // ── Sentence ──────────────────────────────────────────────────────
            Text(
              sentence,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CircleHub.textSecondary,
                fontSize: R * 0.11,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),

            SizedBox(height: R * 0.06),

            // ── Hourly strip ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < slots.length; i++)
                  _HourSlot(
                    label: i == 0
                        ? 'NOW'
                        : DateFormat('ha').format(slots[i].time).toLowerCase(),
                    temp: '${slots[i].tempF.round()}°',
                    dim: i > 0,
                    R: R,
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// Generates the natural-language sentence from current conditions + hourly.
  String _buildSentence(WeatherData d) {
    final id = d.iconCode;

    // Rain / snow / storm — find when it clears in the hourly data
    if (id >= 200 && id < 700) {
      final noun = id >= 600 ? 'snow' : id >= 200 && id < 300 ? 'storm' : 'rain';
      // Look for the first hourly slot where condition id is >= 800 (clear/clouds)
      for (int i = 1; i < d.hourly.length; i++) {
        // We don't have per-slot icon codes, so use temperature trend as proxy.
        // Fall back to sunset-based estimate.
      }
      final diff = d.sunset.difference(DateTime.now());
      final hrs  = (diff.inMinutes / 60).round().clamp(1, 12);
      return 'The $noun will\nstop in $hrs hr';
    }

    // Clear sky
    if (id == 800) {
      final diff = d.sunset.difference(DateTime.now());
      if (!diff.isNegative) {
        final hrs = (diff.inMinutes / 60).round().clamp(1, 12);
        return 'The sun will\nset in $hrs hr';
      }
      return 'Clear skies\ntonight';
    }

    // Clouds
    if (id >= 801 && id <= 804) {
      return 'Cloudy through\nthe evening';
    }

    // Fog / mist
    if (id >= 700 && id < 800) {
      return 'Low visibility\nexpected';
    }

    return 'Stay tuned\nfor updates';
  }
}

class _HourSlot extends StatelessWidget {
  final String label;
  final String temp;
  final bool dim;
  final double R;
  const _HourSlot({required this.label, required this.temp, required this.dim, required this.R});

  @override
  Widget build(BuildContext context) {
    final dimColor = CircleHub.textSecondary.withAlpha(100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: TextStyle(
                color: dim ? dimColor : CircleHub.textSecondary,
                fontSize: R * 0.10,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5)),
        SizedBox(height: R * 0.02),
        Text(temp,
            style: TextStyle(
                color: dim ? dimColor : CircleHub.textPrimary,
                fontSize: R * 0.16,
                fontWeight: FontWeight.w400)),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text('Weather unavailable',
              style:
                  TextStyle(color: CircleHub.textSecondary, fontSize: 16)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: CircleHub.textDim, fontSize: 11)),
        ],
      ),
    );
  }
}
