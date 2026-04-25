import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

/// Loads photos from the local gallery directory.
/// Falls back to curated Unsplash photos when none have been uploaded yet.
final galleryPhotosProvider = FutureProvider.autoDispose<List<_Photo>>((ref) async {
  try {
    final base = await getApplicationDocumentsDirectory();
    final dir  = Directory('${base.path}/gallery');
    if (await dir.exists()) {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => _isImage(f.path))
          .toList()
        ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
      if (files.isNotEmpty) {
        return files.map((f) => _Photo.local(f)).toList();
      }
    }
  } catch (_) {}
  return _kDefaultPhotos.map(_Photo.network).toList();
});

bool _isImage(String path) {
  final p = path.toLowerCase();
  return p.endsWith('.jpg') || p.endsWith('.jpeg') ||
         p.endsWith('.png') || p.endsWith('.webp');
}

// ── Photo discriminated union ─────────────────────────────────────────────────

class _Photo {
  final File? file;
  final String? url;
  const _Photo._({this.file, this.url});
  factory _Photo.local(File f) => _Photo._(file: f);
  factory _Photo.network(String u) => _Photo._(url: u);
  String get key => file?.path ?? url!;
}

const _kDefaultPhotos = [
  'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1080&q=80',
  'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1080&q=80',
  'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=1080&q=80',
  'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=1080&q=80',
  'https://images.unsplash.com/photo-1433086966358-54859d0ed716?w=1080&q=80',
  'https://images.unsplash.com/photo-1518173946687-a4c8892bbd9f?w=1080&q=80',
];

// ── Page ──────────────────────────────────────────────────────────────────────

class GalleryPage extends ConsumerStatefulWidget {
  const GalleryPage({super.key});

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  Timer? _cycleTimer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  void _startCycleTimer(int photoCount) {
    _cycleTimer?.cancel();
    if (photoCount > 1) {
      _cycleTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _advance(photoCount);
      });
    }
  }

  void _advance(int total) {
    _fadeCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _current = (_current + 1) % total);
        _fadeCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(galleryPhotosProvider);

    return async.when(
      loading: () => Container(color: CircleHub.background),
      error: (_, __) => _buildFrame(_kDefaultPhotos.map(_Photo.network).toList()),
      data: (photos) {
        _startCycleTimer(photos.length);
        final safeIndex = _current.clamp(0, photos.length - 1);
        return _buildFrame(photos, currentIndex: safeIndex);
      },
    );
  }

  Widget _buildFrame(List<_Photo> photos, {int currentIndex = 0}) {
    final photo = photos[currentIndex];
    return GestureDetector(
      onTap: () => _advance(photos.length),
      child: FadeTransition(
        opacity: _fade,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image — local file or network URL
            if (photo.file != null)
              Image.file(
                photo.file!,
                key: ValueKey(photo.key),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _errorPlaceholder(),
              )
            else
              CachedNetworkImage(
                imageUrl: photo.url!,
                key: ValueKey(photo.key),
                fit: BoxFit.cover,
                memCacheWidth: 1080,
                memCacheHeight: 1080,
                placeholder: (_, __) => Container(color: CircleHub.background),
                errorWidget: (_, __, ___) => _errorPlaceholder(),
              ),

            // Vignette
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.transparent, Color(0xAA000000)],
                  stops: [0.55, 1.0],
                ),
              ),
            ),

            // Progress dots
            Align(
              alignment: const Alignment(0, 0.82),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == currentIndex ? 16 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == currentIndex
                          ? Colors.white
                          : Colors.white.withAlpha(80),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorPlaceholder() => Container(
        color: CircleHub.surface,
        child: const Center(
            child: Text('📷', style: TextStyle(fontSize: 60))),
      );
}
