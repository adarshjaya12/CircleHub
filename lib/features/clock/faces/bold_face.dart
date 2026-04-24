import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// Face 2 — BOLD
/// Giant stacked hour / minute numbers, weight 900.
/// Thin red second progress bar at the bottom.
class BoldFace extends StatelessWidget {
  final Animation<double> animation;
  const BoldFace({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final now = DateTime.now();
        final h = now.hour.toString().padLeft(2, '0');
        final m = now.minute.toString().padLeft(2, '0');
        final secProgress = (now.second + now.millisecond / 1000) / 60;

        return LayoutBuilder(builder: (_, box) {
          final R = box.maxWidth / 2;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: CircleHub.background),

              // ── Stacked numbers ─────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(h,
                        style: TextStyle(
                          color: CircleHub.textPrimary,
                          fontSize: R * 0.72,
                          fontWeight: FontWeight.w900,
                          height: 0.88,
                          letterSpacing: -6,
                        )),
                    Text(m,
                        style: TextStyle(
                          color: CircleHub.textPrimary,
                          fontSize: R * 0.72,
                          fontWeight: FontWeight.w900,
                          height: 0.88,
                          letterSpacing: -6,
                        )),
                  ],
                ),
              ),

              // ── Second progress bar ──────────────────────────────────────
              Positioned(
                bottom: R * 0.26,
                left: R * 0.22,
                right: R * 0.22,
                child: Stack(children: [
                  Container(height: 2, color: CircleHub.textDim.withAlpha(60)),
                  FractionallySizedBox(
                    widthFactor: secProgress,
                    child: Container(height: 2, color: CircleHub.handSecond),
                  ),
                ]),
              ),

              // ── Day label ────────────────────────────────────────────────
              Positioned(
                top: R * 0.24,
                left: 0, right: 0,
                child: Text(
                  _dayLabel(now),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CircleHub.textDim,
                    fontSize: R * 0.06,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  String _dayLabel(DateTime d) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[d.weekday - 1];
  }
}
