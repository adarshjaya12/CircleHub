import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/device_service.dart';
import '../../core/constants.dart';
import '../../hub/hub_page.dart';

/// Shown on first boot while the device registers with the API.
/// Displays the device ID so the user can pair it in the companion app.
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  String _deviceId = '';
  String _status   = 'Connecting…';
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _init();
  }

  Future<void> _init() async {
    // Retrieve / generate the device ID first (doesn't need the API)
    final prefs    = await SharedPreferences.getInstance();
    final existing = prefs.getString('device_id');
    final id       = existing ?? DeviceService.generateId();
    if (existing == null) await prefs.setString('device_id', id);
    if (mounted) setState(() => _deviceId = id);

    // Attempt to register and get a JWT
    try {
      await DeviceService().getToken();
      if (mounted) {
        setState(() {
          _status = 'Ready — open the CircleHub app to pair';
          _canProceed = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = 'No server connection — tap to continue offline';
          _canProceed = true;
        });
      }
    }
  }

  void _proceed() {
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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final R = CircleHub.radius;
    return Scaffold(
      backgroundColor: CircleHub.background,
      body: GestureDetector(
        onTap: _canProceed ? _proceed : null,
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing ring
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  return CustomPaint(
                    size: Size(R * 2, R * 2),
                    painter: _RingPainter(_pulse.value),
                  );
                },
              ),

              // Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: R * 0.22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pair this device',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Device ID box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFF5A623).withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _deviceId.isEmpty ? '…' : _deviceId,
                        style: GoogleFonts.robotoMono(
                          color: const Color(0xFFF5A623),
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                    ),

                    if (_canProceed) ...[
                      const SizedBox(height: 20),
                      Text(
                        'tap to continue',
                        style: GoogleFonts.outfit(
                          color: Colors.white24,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  const _RingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r  = size.width / 2 * 0.92;
    final opacity = 0.08 + 0.12 * math.sin(t * math.pi);
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = Color.fromRGBO(245, 166, 35, opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}
