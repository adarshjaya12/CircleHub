import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Face 7 — LIGHT
/// Crisp white background, dark analog hands, minimal markers.
/// Clean Apple-Watch-inspired look.
class LightFace extends StatelessWidget {
  final Animation<double> animation;
  const LightFace({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => CustomPaint(
          painter: _LightPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _LightPainter extends CustomPainter {
  // Light-theme palette
  static const _bg        = Color(0xFFFFFFFF);
  static const _ink       = Color(0xFF1C1C1E); // near-black
  static const _inkDim    = Color(0xFF8E8E93); // iOS system gray
  static const _accent    = Color(0xFFFF3B30); // iOS red (second hand)

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final c   = Offset(size.width / 2, size.height / 2);
    final R   = size.width / 2;

    // ── Background ──────────────────────────────────────────────────────────
    canvas.drawCircle(c, R, Paint()..color = _bg);

    // ── Subtle inner shadow ring ────────────────────────────────────────────
    canvas.drawCircle(
      c, R - 1,
      Paint()
        ..color = Colors.black.withAlpha(18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // ── Hour tick marks ─────────────────────────────────────────────────────
    for (int i = 0; i < 60; i++) {
      final angle  = (i / 60) * 2 * math.pi - math.pi / 2;
      final isMajor = i % 5 == 0;
      final len    = isMajor ? R * 0.08 : R * 0.03;
      final width  = isMajor ? 2.5 : 1.0;
      final color  = isMajor ? _ink : _inkDim.withAlpha(80);
      final outer  = c + Offset(math.cos(angle) * R * 0.91, math.sin(angle) * R * 0.91);
      final inner  = c + Offset(math.cos(angle) * (R * 0.91 - len),
                                  math.sin(angle) * (R * 0.91 - len));
      canvas.drawLine(outer, inner,
        Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round);
    }

    // ── Hour hand ───────────────────────────────────────────────────────────
    _hand(canvas, c,
      angle: _angle((now.hour % 12) + now.minute / 60.0, 12),
      len: R * 0.46,
      tail: R * 0.10,
      width: 6.0,
      color: _ink,
    );

    // ── Minute hand ─────────────────────────────────────────────────────────
    _hand(canvas, c,
      angle: _angle(now.minute + now.second / 60.0, 60),
      len: R * 0.68,
      tail: R * 0.12,
      width: 4.0,
      color: _ink,
    );

    // ── Second hand ─────────────────────────────────────────────────────────
    _hand(canvas, c,
      angle: _angle(now.second + now.millisecond / 1000.0, 60),
      len: R * 0.72,
      tail: R * 0.16,
      width: 1.5,
      color: _accent,
    );

    // ── Center cap ──────────────────────────────────────────────────────────
    canvas.drawCircle(c, 7, Paint()..color = _ink);
    canvas.drawCircle(c, 4, Paint()..color = _accent);
    canvas.drawCircle(c, 2, Paint()..color = _bg);

    // ── Digital time (small, below center) ──────────────────────────────────
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    _drawText(canvas, c,
      text: '$hh:$mm',
      fontSize: R * 0.085,
      color: _inkDim,
      dy: R * 0.34,
    );
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
        ..color     = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawText(Canvas canvas, Offset c, {
    required String text,
    required double fontSize,
    required Color color,
    double dy = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          letterSpacing: 2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c + Offset(-tp.width / 2, -tp.height / 2 + dy));
  }

  double _angle(double val, double total) =>
      (val / total) * 2 * math.pi - math.pi / 2;

  @override
  bool shouldRepaint(_LightPainter _) => true;
}
