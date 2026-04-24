import 'package:flutter/material.dart';
import '../clock_painter.dart';

/// Face 1 — CLASSIC
/// The original analog clock with Roman numerals and sweeping hands.
class ClassicFace extends StatelessWidget {
  final Animation<double> animation;
  const ClassicFace({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => CustomPaint(
          painter: ClockPainter(animation: animation),
          size: Size.infinite,
        ),
      ),
    );
  }
}
