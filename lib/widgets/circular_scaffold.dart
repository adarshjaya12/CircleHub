import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Wraps all page content in a 1080×1080 circle.
///
/// On the actual hardware (flutter-pi --clipping-radius 540) the OS clips
/// the framebuffer to a circle. This widget clips in Flutter too so desktop
/// development looks identical.
class CircularScaffold extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const CircularScaffold({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  // ── Toggle this to show the circle boundary during development ─────────────
  static const bool _debugRing = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? CircleHub.background,
      body: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipOval(
                child: SizedBox.expand(child: child),
              ),
              if (_debugRing)
                IgnorePointer(
                  child: CustomPaint(painter: _RingPainter()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    canvas.drawCircle(
      c, R - 1,
      Paint()
        ..color = const Color(0xFFE63946).withAlpha(180) // red ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Safe-zone inner guide (R * 0.20 inset from each side)
    canvas.drawCircle(
      c, R * 0.80,
      Paint()
        ..color = const Color(0xFFFFFFFF).withAlpha(25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_RingPainter _) => false;
}
