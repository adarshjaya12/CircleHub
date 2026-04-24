import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// High-performance analog clock face drawn entirely with [Canvas].
///
/// The [animation] is used as the repaint listenable so Flutter only
/// repaints this layer at the animation's tick rate (≈60fps).
/// All other widgets (date text, page indicator) live outside this
/// [RepaintBoundary] and repaint independently.
class ClockPainter extends CustomPainter {
  final Animation<double> animation;

  ClockPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2; // full radius of the canvas

    // ── Background ──────────────────────────────────────────────────────────
    canvas.drawCircle(center, R, Paint()..color = CircleHub.background);

    // ── Subtle inner ambient glow ────────────────────────────────────────────
    final glowShader = RadialGradient(
      colors: [CircleHub.surface.withAlpha(180), Colors.transparent],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: R * 0.55));
    canvas.drawCircle(center, R * 0.55, Paint()..shader = glowShader);

    // ── Minute tick marks ────────────────────────────────────────────────────
    for (int i = 0; i < 60; i++) {
      final angle = _angleForUnit(i.toDouble(), 60);
      final isHour = i % 5 == 0;
      final outerR = R * 0.94;
      final innerR = isHour ? R * 0.81 : R * 0.89;

      canvas.drawLine(
        center + Offset(math.cos(angle) * innerR, math.sin(angle) * innerR),
        center + Offset(math.cos(angle) * outerR, math.sin(angle) * outerR),
        Paint()
          ..color = isHour ? CircleHub.tickMajor : CircleHub.tickMinor
          ..strokeWidth = isHour ? 2.0 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Roman numeral hour labels ────────────────────────────────────────────
    const romans = ['XII', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI'];
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int h = 0; h < 12; h++) {
      final angle = _angleForUnit(h.toDouble(), 12);
      final pos = center + Offset(math.cos(angle) * R * 0.70, math.sin(angle) * R * 0.70);
      tp
        ..text = TextSpan(
          text: romans[h],
          style: TextStyle(
            color: CircleHub.textSecondary.withAlpha(120),
            fontSize: R * 0.052,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
        )
        ..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // ── Hour hand ────────────────────────────────────────────────────────────
    final hourAngle = _angleForUnit(
      (now.hour % 12) + now.minute / 60.0 + now.second / 3600.0,
      12,
    );
    _drawHand(canvas, center,
      angle: hourAngle,
      length: R * 0.44,
      tail: R * 0.10,
      width: 5.5,
      color: CircleHub.handHour,
    );

    // ── Minute hand ──────────────────────────────────────────────────────────
    final minuteAngle = _angleForUnit(
      now.minute + now.second / 60.0,
      60,
    );
    _drawHand(canvas, center,
      angle: minuteAngle,
      length: R * 0.63,
      tail: R * 0.12,
      width: 3.5,
      color: CircleHub.handMinute,
    );

    // ── Second hand — smooth sub-second precision ────────────────────────────
    final secondVal = now.second + now.millisecond / 1000.0;
    final secondAngle = _angleForUnit(secondVal, 60);
    _drawHand(canvas, center,
      angle: secondAngle,
      length: R * 0.72,
      tail: R * 0.16,
      width: 1.5,
      color: CircleHub.handSecond,
    );

    // Second counterweight circle
    canvas.drawCircle(
      center + Offset(math.cos(secondAngle + math.pi) * R * 0.12,
                      math.sin(secondAngle + math.pi) * R * 0.12),
      6,
      Paint()..color = CircleHub.handSecond,
    );

    // ── Center cap ───────────────────────────────────────────────────────────
    canvas.drawCircle(center, 9, Paint()..color = CircleHub.handHour);
    canvas.drawCircle(center, 4, Paint()..color = CircleHub.handSecond);
  }

  void _drawHand(
    Canvas canvas,
    Offset center, {
    required double angle,
    required double length,
    required double tail,
    required double width,
    required Color color,
  }) {
    final tip  = center + Offset(math.cos(angle) * length, math.sin(angle) * length);
    final base = center - Offset(math.cos(angle) * tail,  math.sin(angle) * tail);
    canvas.drawLine(
      base, tip,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Converts a value (e.g. hours 0–12, minutes 0–60) to a canvas angle
  /// where 12 o'clock = -π/2 (top of circle).
  double _angleForUnit(double value, double total) =>
      (value / total) * 2 * math.pi - math.pi / 2;

  @override
  bool shouldRepaint(ClockPainter old) => true;
}
