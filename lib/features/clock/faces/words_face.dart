import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// Face 5 — WORDS
/// Spells out the time in plain English, poetry-clock style.
/// e.g.  NINE
///       TWENTY
///       TWO
class WordsFace extends StatelessWidget {
  final Animation<double> animation;
  const WordsFace({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final now    = DateTime.now();
        final lines  = _timeWords(now);
        // Show seconds as a very faint progress bar at bottom
        final secProgress = (now.second + now.millisecond / 1000) / 60;

        return LayoutBuilder(builder: (_, box) {
          final R = box.maxWidth / 2;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: CircleHub.background),

              // ── Word lines ──────────────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (int i = 0; i < lines.length; i++) ...[
                      Text(
                        lines[i],
                        style: TextStyle(
                          color: i == 0
                              ? CircleHub.textPrimary
                              : CircleHub.textSecondary.withAlpha(i == 1 ? 200 : 140),
                          fontSize: R * (i == 0 ? 0.22 : 0.14),
                          fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w300,
                          letterSpacing: i == 0 ? 2.0 : 4.0,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Seconds progress dot row ────────────────────────────────────
              Positioned(
                bottom: R * 0.28,
                left: R * 0.30,
                right: R * 0.30,
                child: Stack(children: [
                  Container(height: 1.5, color: CircleHub.textDim.withAlpha(40)),
                  FractionallySizedBox(
                    widthFactor: secProgress,
                    child: Container(height: 1.5, color: CircleHub.handSecond.withAlpha(160)),
                  ),
                ]),
              ),

              // ── AM / PM tag ─────────────────────────────────────────────────
              Positioned(
                bottom: R * 0.34,
                left: 0, right: 0,
                child: Text(
                  now.hour < 12 ? 'AM' : 'PM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CircleHub.textDim.withAlpha(100),
                    fontSize: R * 0.055,
                    letterSpacing: 5,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  /// Returns 2–3 lines spelling out the time.
  /// Hour is always first (nominative form).
  /// Minute follows if non-zero.
  List<String> _timeWords(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute;

    const nums = [
      'TWELVE', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX',
      'SEVEN', 'EIGHT', 'NINE', 'TEN', 'ELEVEN', 'TWELVE',
    ];
    const tens = ['', '', 'TWENTY', 'THIRTY', 'FORTY', 'FIFTY'];
    const teens = [
      'TEN', 'ELEVEN', 'TWELVE', 'THIRTEEN', 'FOURTEEN', 'FIFTEEN',
      'SIXTEEN', 'SEVENTEEN', 'EIGHTEEN', 'NINETEEN',
    ];

    String minuteWord(int m) {
      if (m == 0) return '';
      if (m < 10) return 'OH ${nums[m]}';
      if (m < 20) return teens[m - 10];
      final t = m ~/ 10;
      final u = m % 10;
      return u == 0 ? tens[t] : '${tens[t]} ${nums[u]}';
    }

    final mw = minuteWord(m);
    return [
      nums[h],
      if (mw.isNotEmpty) mw,
    ];
  }
}
