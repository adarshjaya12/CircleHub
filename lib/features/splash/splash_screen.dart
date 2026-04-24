import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../hub/hub_page.dart';

// ── Timing constants (seconds, matching HTML design) ─────────────────────
class _T {
  static const double duration   = 5.6;
  static const double glowEnd    = 0.65;
  static const double arcEnd     = 1.4;
  static const double wordStart  = 1.85;
  static const double pulseStart = 2.8;
  static const double pulseEnd   = 3.75;
  static const double fadeStart  = 3.9;
  static const double fadeEnd    = 5.1;
}

// ── Easing helpers ────────────────────────────────────────────────────────
double _clamp01(double v) => v.clamp(0.0, 1.0);

double _easeOutCubic(double t) {
  final s = t - 1;
  return s * s * s + 1;
}

double _easeInOutCubic(double t) =>
    t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;

double _easeInOutQuad(double t) =>
    t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

double _tween({
  required double t,
  required double start,
  required double end,
  double from = 0.0,
  double to = 1.0,
  double Function(double)? ease,
}) {
  if (t <= start) return from;
  if (t >= end) return to;
  final local = (t - start) / (end - start);
  final eased = ease != null ? ease(local) : local;
  return from + (to - from) * eased;
}

// ── Canvas: background + glow + arc ──────────────────────────────────────
class _SplashPainter extends CustomPainter {
  final double t;
  const _SplashPainter(this.t);

  static const _bg     = Color(0xFF060608);
  static const _accent = Color(0xFFF5A623);

  @override
  void paint(Canvas canvas, Size size) {
    const double W = 1080, H = 1080;
    const double cx = W / 2, cy = H / 2;
    const double R = W / 2;

    // Scale to widget size
    canvas.scale(size.width / W, size.height / H);

    // Clip to circle
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(center: const Offset(cx, cy), radius: R)));

    // Background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, W, H),
      Paint()..color = _bg,
    );

    // ── Radial glow ──────────────────────────────────────────────────────
    final glowP = _easeOutCubic(_clamp01(t / _T.glowEnd));
    if (glowP > 0) {
      canvas.drawCircle(
        const Offset(cx, cy),
        R * 0.72,
        Paint()
          ..shader = RadialGradient(colors: [
            Color.fromRGBO(245, 166, 35, 0.09 * glowP),
            Color.fromRGBO(245, 166, 35, 0.04 * glowP),
            const Color.fromRGBO(245, 166, 35, 0),
          ], stops: const [0.0, 0.5, 1.0]).createShader(
              Rect.fromCircle(center: const Offset(cx, cy), radius: R * 0.72)),
      );
      canvas.drawCircle(
        const Offset(cx, cy),
        R * 0.52,
        Paint()
          ..shader = RadialGradient(colors: [
            Color.fromRGBO(15, 15, 20, 0.9 * glowP),
            const Color.fromRGBO(15, 15, 20, 0),
          ]).createShader(
              Rect.fromCircle(center: const Offset(cx, cy), radius: R * 0.52)),
      );
    }

    // ── Arc track (dim ring) ─────────────────────────────────────────────
    final trackOpacity = _clamp01(t / 0.3);
    canvas.drawCircle(
      const Offset(cx, cy),
      R * 0.955,
      Paint()
        ..color = Color.fromRGBO(58, 58, 74, 0.35 * trackOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // ── Gold progress arc ─────────────────────────────────────────────────
    final arcP = _easeInOutCubic(_clamp01(t / _T.arcEnd));
    if (arcP > 0) {
      const startAngle = -math.pi / 2;
      final sweepAngle = arcP * math.pi * 2;
      final arcRect =
          Rect.fromCircle(center: const Offset(cx, cy), radius: R * 0.955);

      // Glow layer
      canvas.drawArc(
        arcRect, startAngle, sweepAngle, false,
        Paint()
          ..color = const Color.fromRGBO(245, 166, 35, 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
      );

      // Crisp arc
      canvas.drawArc(
        arcRect, startAngle, sweepAngle, false,
        Paint()
          ..color = _accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );

      // Leading dot at arc tip
      if (arcP < 0.998) {
        final tipAngle = startAngle + sweepAngle;
        final tipX = cx + math.cos(tipAngle) * R * 0.955;
        final tipY = cy + math.sin(tipAngle) * R * 0.955;
        canvas.drawCircle(
          Offset(tipX, tipY), 5,
          Paint()
            ..color = Colors.white
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
        canvas.drawCircle(Offset(tipX, tipY), 4, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(_SplashPainter old) => old.t != t;
}

// ── Splash Screen ─────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _chars = ['C','i','r','c','l','e',' ','H','u','b'];
  static const _charStagger = 0.062;
  static const _charDur     = 0.22;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..forward().whenComplete(_navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HubPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060608),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value * _T.duration;

          // Derived animation values
          final lastCharEnd =
              _T.wordStart + (_chars.length - 1) * _charStagger + _charDur;
          final shimmerStart = lastCharEnd + 0.5;

          final shimmerP  = _tween(t: t, start: shimmerStart,
              end: shimmerStart + 0.7, ease: _easeInOutQuad);
          final underlineP = _tween(t: t, start: lastCharEnd,
              end: lastCharEnd + 0.45, ease: _easeInOutCubic);
          final blackOpacity = _tween(t: t,
              start: _T.fadeStart, end: _T.fadeEnd, ease: _easeInOutCubic);
          final screenAlpha = 1.0 - _tween(t: t,
              start: _T.fadeStart, end: _T.fadeEnd);

          final pulsePhase = _clamp01(
              (t - _T.pulseStart) / (_T.pulseEnd - _T.pulseStart));
          final pulseOpacity =
              (t >= _T.pulseStart && t <= _T.pulseEnd)
                  ? math.sin(pulsePhase * math.pi) * 0.14
                  : 0.0;

          return Stack(
            children: [
              // Canvas: glow + arc
              Positioned.fill(
                child: CustomPaint(painter: _SplashPainter(t)),
              ),

              // Wordmark
              Opacity(
                opacity: screenAlpha.clamp(0.0, 1.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: List.generate(_chars.length, (i) {
                          final charStart = _T.wordStart + i * _charStagger;
                          final localT = _clamp01((t - charStart) / _charDur);
                          final p = _easeOutCubic(localT);

                          final shimmerBright = (shimmerP > 0 && shimmerP < 1)
                              ? math.max(0.0,
                                      0.8 -
                                          (shimmerP - i / _chars.length).abs() *
                                              4) *
                                  1.4
                              : 0.0;

                          return Transform.translate(
                            offset: Offset(0, (1 - p) * 18),
                            child: Opacity(
                              opacity: p.clamp(0.0, 1.0),
                              child: Text(
                                _chars[i] == ' ' ? '\u00A0' : _chars[i],
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w200,
                                  fontSize: 40,
                                  letterSpacing: _chars[i] == ' ' ? 12.8 : 11.2,
                                  color: Color.lerp(
                                    const Color(0xFFE8E8EC),
                                    Colors.white,
                                    shimmerBright.clamp(0.0, 1.0),
                                  ),
                                  height: 1,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      // Gold underline draws left → right
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: underlineP,
                            child: Container(
                              width: 200,
                              height: 0.8,
                              color: const Color(0xFFF5A623).withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Gold pulse overlay
              if (pulseOpacity > 0)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Color.fromRGBO(245, 166, 35, pulseOpacity),
                          Color.fromRGBO(245, 166, 35, pulseOpacity * 0.4),
                          const Color.fromRGBO(245, 166, 35, 0),
                        ],
                        stops: const [0.0, 0.4, 0.72],
                      ),
                    ),
                  ),
                ),

              // Fade to black
              Positioned.fill(
                child: ColoredBox(
                  color: Color.fromRGBO(6, 6, 8, blackOpacity),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
