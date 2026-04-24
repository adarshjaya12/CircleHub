import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';

/// Photo-frame mode — cycles landscape images every 30 seconds.
/// Uses [CachedNetworkImage] to keep RAM pressure low on Pi Zero 2W:
/// images are decoded at display resolution (1080×1080) and cached to disk.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with SingleTickerProviderStateMixin {
  // Unsplash curated landscape/nature photos — no API key required for direct URLs.
  // Replace with your own curated list or point at a local media server.
  static const _imageUrls = [
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&q=80',
    'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1080&q=80',
    'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=1080&q=80',
    'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=1080&q=80',
    'https://images.unsplash.com/photo-1433086966358-54859d0ed716?w=1080&q=80',
    'https://images.unsplash.com/photo-1518173946687-a4c8892bbd9f?w=1080&q=80',
  ];

  int _current = 0;
  late Timer _cycleTimer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();

    _cycleTimer = Timer.periodic(const Duration(seconds: 30), (_) => _advance());
  }

  void _advance() {
    _fadeCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _current = (_current + 1) % _imageUrls.length);
        _fadeCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _cycleTimer.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _advance,
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Photo ─────────────────────────────────────────────────────
            CachedNetworkImage(
              imageUrl: _imageUrls[_current],
              fit: BoxFit.cover,
              memCacheWidth: 1080,
              memCacheHeight: 1080,
              placeholder: (_, __) => Container(color: CircleHub.background),
              errorWidget: (_, __, ___) => Container(
                color: CircleHub.surface,
                child: const Center(
                  child: Text('📷', style: TextStyle(fontSize: 60)),
                ),
              ),
            ),

            // ── Subtle vignette ───────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.transparent, Color(0xAA000000)],
                  stops: [0.55, 1.0],
                ),
              ),
            ),

            // ── Progress dots ─────────────────────────────────────────────
            Align(
              alignment: const Alignment(0, 0.82),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_imageUrls.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 16 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == _current
                          ? Colors.white
                          : Colors.white.withAlpha(80),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  );
                }),
              ),
            ),

            // ── Tap-to-next hint ──────────────────────────────────────────
            Align(
              alignment: const Alignment(0, 0.92),
              child: Text(
                'TAP TO ADVANCE',
                style: TextStyle(
                  color: Colors.white.withAlpha(60),
                  fontSize: 10,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
