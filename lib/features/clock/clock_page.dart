import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'faces/classic_face.dart';
import 'faces/bold_face.dart';
import 'faces/minimal_face.dart';
import 'faces/retro_face.dart';
import 'faces/words_face.dart';
import 'faces/orbit_face.dart';
import 'faces/light_face.dart';
import 'faces/ticker_face.dart';
import 'faces/triple_face.dart';

enum ClockFaceStyle { classic, bold, minimal, retro, words, orbit, light, ticker, triple }

extension _Label on ClockFaceStyle {
  String get label => switch (this) {
    ClockFaceStyle.classic => 'CLASSIC',
    ClockFaceStyle.bold    => 'BOLD',
    ClockFaceStyle.minimal => 'MINIMAL',
    ClockFaceStyle.retro   => 'RETRO',
    ClockFaceStyle.words   => 'WORDS',
    ClockFaceStyle.orbit   => 'ORBIT',
    ClockFaceStyle.light   => 'LIGHT',
    ClockFaceStyle.ticker  => 'TICKER',
    ClockFaceStyle.triple  => 'TRIPLE',
  };
}

/// Home screen: full-circle clock with 6 swappable face styles.
/// Tap anywhere to cycle to the next style.
/// The face name flashes for 2 s after each switch.
class ClockPage extends StatefulWidget {
  const ClockPage({super.key});

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  ClockFaceStyle _style = ClockFaceStyle.classic;
  bool _showLabel = false;
  Timer? _labelTimer;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _labelTimer?.cancel();
    super.dispose();
  }

  void _cycleFace() {
    final styles = ClockFaceStyle.values;
    final next   = styles[(_style.index + 1) % styles.length];
    setState(() {
      _style     = next;
      _showLabel = true;
    });
    _labelTimer?.cancel();
    _labelTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showLabel = false);
    });
  }

  Widget _buildFace() => switch (_style) {
    ClockFaceStyle.classic => ClassicFace(animation: _ticker),
    ClockFaceStyle.bold    => BoldFace(animation: _ticker),
    ClockFaceStyle.minimal => MinimalFace(animation: _ticker),
    ClockFaceStyle.retro   => RetroFace(animation: _ticker),
    ClockFaceStyle.words   => WordsFace(animation: _ticker),
    ClockFaceStyle.orbit   => OrbitFace(animation: _ticker),
    ClockFaceStyle.light   => LightFace(animation: _ticker),
    ClockFaceStyle.ticker  => TickerFace(animation: _ticker),
    ClockFaceStyle.triple  => TripleFace(animation: _ticker),
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _cycleFace,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Active face ───────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: KeyedSubtree(
              key: ValueKey(_style),
              child: _buildFace(),
            ),
          ),

          // ── Face name label (shown 2 s after tap) ─────────────────────────
          AnimatedOpacity(
            opacity: _showLabel ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Align(
              alignment: const Alignment(0, 0.78),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _style.label,
                  style: TextStyle(
                    color: CircleHub.textSecondary.withAlpha(200),
                    fontSize: 11,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),

          // ── Swipe-right hint (very faint) ─────────────────────────────────
          Align(
            alignment: const Alignment(0.82, 0),
            child: Icon(
              Icons.chevron_right_rounded,
              color: CircleHub.textDim.withAlpha(50),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
