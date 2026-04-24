import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// Face 8 — DOTS
/// Dense uniform dot grid. Only dots whose center sits inside the clock
/// circle are drawn — no clipping artifacts at the edges.
class DotsFace extends StatelessWidget {
  final Animation<double> animation;
  const DotsFace({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => CustomPaint(
          painter: _DotsPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final c   = Offset(size.width / 2, size.height / 2);
    final R   = size.width / 2;

    // ── Background ──────────────────────────────────────────────────────────
    canvas.drawCircle(c, R, Paint()..color = CircleHub.background);

    // ── Dot grid ────────────────────────────────────────────────────────────
    // Spacing between dot centres. Smaller = denser.
    final spacing = R * 0.068;
    // Dot radius — kept small so there is plenty of dark gap between dots.
    final dotR    = spacing * 0.14;
    // Only draw a dot if its centre is fully inside the face (no clipping).
    final maxDist = R * 0.91 - dotR;

    final startX = c.dx - R;
    final startY = c.dy - R;
    final count  = (R * 2 / spacing).ceil() + 2;

    final dotPaint = Paint()..color = Colors.white.withAlpha(110);

    for (int row = 0; row < count; row++) {
      for (int col = 0; col < count; col++) {
        final x   = startX + col * spacing;
        final y   = startY + row * spacing;
        final dot = Offset(x, y);
        if ((dot - c).distance > maxDist) continue; // skip outside & edge dots
        canvas.drawCircle(dot, dotR, dotPaint);
      }
    }

    // ── Hour hand ───────────────────────────────────────────────────────────
    _hand(canvas, c,
      angle: _angle((now.hour % 12) + now.minute / 60.0, 12),
      len:   R * 0.46,
      tail:  R * 0.10,
      width: 5.0,
      color: Colors.white,
    );

    // ── Minute hand ─────────────────────────────────────────────────────────
    _hand(canvas, c,
      angle: _angle(now.minute + now.second / 60.0, 60),
      len:   R * 0.68,
      tail:  R * 0.12,
      width: 3.0,
      color: Colors.white.withAlpha(220),
    );

    // ── Second hand ─────────────────────────────────────────────────────────
    _hand(canvas, c,
      angle: _angle(now.second + now.millisecond / 1000.0, 60),
      len:   R * 0.72,
      tail:  R * 0.16,
      width: 1.2,
      color: CircleHub.handSecond,
    );

    // ── Center cap ──────────────────────────────────────────────────────────
    canvas.drawCircle(c, 6.0, Paint()..color = Colors.white);
    canvas.drawCircle(c, 3.0, Paint()..color = CircleHub.handSecond);
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
      c + Offset(math.cos(angle) * len,  math.sin(angle) * len),
      Paint()
        ..color      = color
        ..strokeWidth = width
        ..strokeCap  = StrokeCap.round,
    );
  }

  double _angle(double val, double total) =>
      (val / total) * 2 * math.pi - math.pi / 2;

  @override
  bool shouldRepaint(_DotsPainter _) => true;
}
