import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// Face 6 — ORBIT
/// Large hour number at center.
/// Minute shown as a glowing arc sweeping around the outside.
/// Second shown as a faster, thinner trailing arc.
class OrbitFace extends StatelessWidget {
  final Animation<double> animation;
  const OrbitFace({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => CustomPaint(
          painter: _OrbitPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final c = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;

    // Background
    canvas.drawCircle(c, R, Paint()..color = CircleHub.background);

    // ── Minute arc (thick, bright) ──────────────────────────────────────────
    final minFrac = (now.minute + now.second / 60.0) / 60.0;
    _drawArc(
      canvas, c, R * 0.82,
      strokeWidth: 8.0,
      fraction: minFrac,
      color: CircleHub.handMinute.withAlpha(220),
      trackColor: CircleHub.textDim.withAlpha(30),
    );

    // ── Second arc (thin, red) ──────────────────────────────────────────────
    final secFrac = (now.second + now.millisecond / 1000.0) / 60.0;
    _drawArc(
      canvas, c, R * 0.92,
      strokeWidth: 2.5,
      fraction: secFrac,
      color: CircleHub.handSecond.withAlpha(200),
      trackColor: Colors.transparent,
    );

    // ── Glowing dot at minute arc tip ──────────────────────────────────────
    final minAngle = _frac2angle(minFrac);
    final minTip = c + Offset(math.cos(minAngle) * R * 0.82,
                               math.sin(minAngle) * R * 0.82);
    canvas.drawCircle(minTip, 6,
      Paint()..color = CircleHub.handMinute..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(minTip, 4, Paint()..color = Colors.white);

    // ── Hour number (large, centered) ──────────────────────────────────────
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    _drawText(
      canvas, c,
      text: hour12.toString().padLeft(2, '0'),
      fontSize: R * 0.60,
      color: CircleHub.textPrimary,
      fontWeight: FontWeight.w800,
      dy: -R * 0.06,
    );

    // ── Minute digits (small, below hour) ──────────────────────────────────
    _drawText(
      canvas, c,
      text: ':${now.minute.toString().padLeft(2, '0')}',
      fontSize: R * 0.18,
      color: CircleHub.textSecondary.withAlpha(180),
      fontWeight: FontWeight.w300,
      dy: R * 0.32,
    );

    // ── Hour marker tick at 12 o'clock ──────────────────────────────────────
    final tickY = c.dy - R * 0.92;
    canvas.drawLine(
      Offset(c.dx, tickY - 6),
      Offset(c.dx, tickY + 6),
      Paint()
        ..color = CircleHub.textDim.withAlpha(80)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawArc(Canvas canvas, Offset c, double radius, {
    required double strokeWidth,
    required double fraction,
    required Color color,
    required Color trackColor,
  }) {
    final rect = Rect.fromCircle(center: c, radius: radius);
    const start = -math.pi / 2; // 12 o'clock

    if (trackColor != Colors.transparent) {
      canvas.drawArc(rect, 0, 2 * math.pi,
          false,
          Paint()
            ..color = trackColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round);
    }

    canvas.drawArc(rect, start, fraction * 2 * math.pi,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round);
  }

  void _drawText(Canvas canvas, Offset c, {
    required String text,
    required double fontSize,
    required Color color,
    required FontWeight fontWeight,
    double dy = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: -2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c + Offset(-tp.width / 2, -tp.height / 2 + dy));
  }

  double _frac2angle(double frac) => frac * 2 * math.pi - math.pi / 2;

  @override
  bool shouldRepaint(_OrbitPainter _) => true;
}
