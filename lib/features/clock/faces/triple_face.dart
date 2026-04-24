import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// Face 10 — TRIPLE
/// Hour, minute, and seconds each on their own line.
/// Minute is the star — largest and brightest.
/// Thin red accent line between hour and minute.
class TripleFace extends StatelessWidget {
  final Animation<double> animation;
  const TripleFace({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final now = DateTime.now();
        final hh  = now.hour.toString().padLeft(2, '0');
        final mm  = now.minute.toString().padLeft(2, '0');
        final ss  = now.second.toString().padLeft(2, '0');

        return LayoutBuilder(builder: (_, box) {
          final R = box.maxWidth / 2;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: CircleHub.background),

              // ── Three stacked numbers ────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Hour (dim, medium)
                    Text(
                      hh,
                      style: TextStyle(
                        color: CircleHub.textSecondary.withAlpha(120),
                        fontSize: R * 0.36,
                        fontWeight: FontWeight.w200,
                        height: 1.0,
                        letterSpacing: -2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),

                    // Red accent divider
                    SizedBox(
                      width: R * 0.60,
                      child: Container(
                          height: 1.5,
                          color: CircleHub.handSecond.withAlpha(180)),
                    ),

                    // Minute (bright, huge)
                    Text(
                      mm,
                      style: TextStyle(
                        color: CircleHub.textPrimary,
                        fontSize: R * 0.58,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        letterSpacing: -4,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),

                    // Seconds (very dim, small)
                    Text(
                      ss,
                      style: TextStyle(
                        color: CircleHub.textDim.withAlpha(100),
                        fontSize: R * 0.20,
                        fontWeight: FontWeight.w300,
                        height: 1.1,
                        letterSpacing: 2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
      },
    );
  }
}
