import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// Face 4 — RETRO
/// Monospace LCD-style digital time with red accent lines.
/// Inspired by the "-09:32-" aesthetic.
class RetroFace extends StatelessWidget {
  final Animation<double> animation;
  const RetroFace({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final now = DateTime.now();
        final hh = now.hour.toString().padLeft(2, '0');
        final mm = now.minute.toString().padLeft(2, '0');
        final ss = now.second.toString().padLeft(2, '0');

        return LayoutBuilder(builder: (_, box) {
          final R = box.maxWidth / 2;
          return Stack(
            fit: StackFit.expand,
            children: [
              Container(color: CircleHub.background),

              // ── Top accent line ────────────────────────────────────────
              Positioned(
                top: R * 0.44,
                left: R * 0.18,
                right: R * 0.18,
                child: Container(height: 1.5, color: CircleHub.handSecond.withAlpha(180)),
              ),

              // ── Main time ─────────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dashes + time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('—',
                            style: TextStyle(
                              color: CircleHub.handSecond.withAlpha(200),
                              fontSize: R * 0.10,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            )),
                        Text(
                          '$hh:$mm',
                          style: TextStyle(
                            color: CircleHub.textPrimary,
                            fontSize: R * 0.32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text('—',
                            style: TextStyle(
                              color: CircleHub.handSecond.withAlpha(200),
                              fontSize: R * 0.10,
                              fontWeight: FontWeight.w300,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            )),
                      ],
                    ),

                    // Seconds
                    Text(
                      ss,
                      style: TextStyle(
                        color: CircleHub.textDim,
                        fontSize: R * 0.11,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 6,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom accent line ─────────────────────────────────────
              Positioned(
                bottom: R * 0.44,
                left: R * 0.18,
                right: R * 0.18,
                child: Container(height: 1.5, color: CircleHub.handSecond.withAlpha(180)),
              ),

              // ── Date bottom ────────────────────────────────────────────
              Positioned(
                bottom: R * 0.30,
                left: 0, right: 0,
                child: Text(
                  _dateStr(now),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CircleHub.textDim,
                    fontSize: R * 0.05,
                    letterSpacing: 3,
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

  String _dateStr(DateTime d) {
    const months = ['JAN','FEB','MAR','APR','MAY','JUN',
                    'JUL','AUG','SEP','OCT','NOV','DEC'];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2,'0')}';
  }
}
