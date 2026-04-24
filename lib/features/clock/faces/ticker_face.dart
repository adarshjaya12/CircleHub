import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// Face 9 — TICKER
/// Slot-machine style: shows the minute above and below the current one,
/// making the current minute feel "live" as it ticks through.
///
/// Layout:
///   [dim]  previous minute
///   [bright] HH : current minute   ← large center
///   [dim]  next minute
class TickerFace extends StatelessWidget {
  final Animation<double> animation;
  const TickerFace({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final now  = DateTime.now();
        final hh   = now.hour.toString().padLeft(2, '0');
        final cur  = now.minute;
        final prev = (cur - 1 + 60) % 60;
        final next = (cur + 1) % 60;

        return LayoutBuilder(builder: (_, box) {
          final R = box.maxWidth / 2;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background
              Container(color: CircleHub.background),

              // ── Thin divider lines ──────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Previous minute (dim, small)
                    Text(
                      prev.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: CircleHub.textDim.withAlpha(80),
                        fontSize: R * 0.22,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),

                    // ── Current time (hour + minute) — large + bright ─────────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Hour
                        Text(
                          hh,
                          style: TextStyle(
                            color: CircleHub.textSecondary.withAlpha(160),
                            fontSize: R * 0.32,
                            fontWeight: FontWeight.w200,
                            letterSpacing: -2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        // Colon — blinks every second
                        Text(
                          now.second % 2 == 0 ? ':' : ' ',
                          style: TextStyle(
                            color: CircleHub.handSecond,
                            fontSize: R * 0.32,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 0,
                          ),
                        ),
                        // Current minute — heaviest weight
                        Text(
                          cur.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: CircleHub.textPrimary,
                            fontSize: R * 0.48,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),

                    // Next minute (dim, small)
                    Text(
                      next.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: CircleHub.textDim.withAlpha(80),
                        fontSize: R * 0.22,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Horizontal divider lines around center ──────────────────────
              Center(
                child: SizedBox(
                  width: R * 1.1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(height: 0.5,
                          color: CircleHub.textDim.withAlpha(60)),
                      SizedBox(height: R * 0.62),
                      Container(height: 0.5,
                          color: CircleHub.textDim.withAlpha(60)),
                    ],
                  ),
                ),
              ),

              // ── Seconds bar at the very bottom ─────────────────────────────
              Positioned(
                bottom: R * 0.22,
                left: R * 0.30,
                right: R * 0.30,
                child: Stack(children: [
                  Container(height: 1.5,
                      color: CircleHub.textDim.withAlpha(40)),
                  FractionallySizedBox(
                    widthFactor: (now.second + now.millisecond / 1000) / 60,
                    child: Container(
                        height: 1.5, color: CircleHub.handSecond.withAlpha(180)),
                  ),
                ]),
              ),
            ],
          );
        });
      },
    );
  }
}
