import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// Face 3 — MINIMAL
/// Pure dots for hour markers, ultra-thin hands, zero text.
/// Second dot sweeps the outer ring instead of a traditional hand.
class MinimalFace extends StatelessWidget {
  final Animation<double> animation;
  const MinimalFace({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => CustomPaint(
          painter: _MinimalPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _MinimalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final c = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;

    // Background
    canvas.drawCircle(c, R, Paint()..color = CircleHub.background);

    // ── Hour marker dots ────────────────────────────────────────────────────
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final dotR = i % 3 == 0 ? 5.0 : 3.0;
      final dist = R * 0.88;
      canvas.drawCircle(
        c + Offset(math.cos(angle) * dist, math.sin(angle) * dist),
        dotR,
        Paint()
          ..color = i % 3 == 0
              ? CircleHub.textSecondary
              : CircleHub.textDim.withAlpha(150),
      );
    }

    // ── Second dot on outer ring ────────────────────────────────────────────
    final secAngle = _angle(now.second + now.millisecond / 1000, 60);
    canvas.drawCircle(
      c + Offset(math.cos(secAngle) * R * 0.88, math.sin(secAngle) * R * 0.88),
      5,
      Paint()..color = CircleHub.handSecond,
    );

    // ── Hour hand ───────────────────────────────────────────────────────────
    _hand(canvas, c,
      angle: _angle((now.hour % 12) + now.minute / 60.0, 12),
      len: R * 0.42,
      tail: R * 0.10,
      width: 3.0,
      color: CircleHub.handHour,
    );

    // ── Minute hand ─────────────────────────────────────────────────────────
    _hand(canvas, c,
      angle: _angle(now.minute + now.second / 60.0, 60),
      len: R * 0.62,
      tail: R * 0.12,
      width: 1.5,
      color: CircleHub.handMinute,
    );

    // ── Center dot ──────────────────────────────────────────────────────────
    canvas.drawCircle(c, 5, Paint()..color = Colors.white);
    canvas.drawCircle(c, 2.5, Paint()..color = CircleHub.handSecond);
  }

  void _hand(Canvas canvas, Offset c, {
    required double angle,
    required double len,
    required double tail,
    required double width,
    required Color color,
  }) {
    canvas.drawLine(
      c - Offset(math.cos(angle) * tail, math.sin(angle) * tail),
      c + Offset(math.cos(angle) * len, math.sin(angle) * len),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  double _angle(double val, double total) =>
      (val / total) * 2 * math.pi - math.pi / 2;

  @override
  bool shouldRepaint(_MinimalPainter _) => true;
}
