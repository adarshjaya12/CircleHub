import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

/// Lightweight HTTP server (port 8080) that lets the companion app
/// push photos directly to the device over local WiFi.
///
/// Photos are stored in `<appDocuments>/gallery/` as JPEG/PNG files.
/// No authentication — relies on local network security.
class LocalServer {
  static const _port = 8080;
  HttpServer? _server;

  Future<void> start() async {
    final router = Router()
      ..get('/api/status',            _status)
      ..get('/api/photos',            _listPhotos)
      ..post('/api/photos',           _addPhoto)
      ..delete('/api/photos/<id>',    _deletePhoto);

    final handler = const Pipeline()
        .addMiddleware(_cors())
        .addHandler(router.call);

    _server = await io.serve(handler, InternetAddress.anyIPv4, _port);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  // ── Handlers ────────────────────────────────────────────────────────────────

  Future<Response> _status(Request req) async {
    return _json({'status': 'ok', 'version': '1.0'});
  }

  Future<Response> _listPhotos(Request req) async {
    final dir = await _galleryDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => _isImage(f.path))
        .map((f) => {'id': _nameOnly(f.path), 'path': f.path})
        .toList();
    files.sort((a, b) =>
        File(a['path']!).statSync().modified
            .compareTo(File(b['path']!).statSync().modified));
    return _json(files);
  }

  /// Body: `{ "id": "<filename-no-ext>", "data": "<base64>", "mimeType": "image/jpeg" }`
  Future<Response> _addPhoto(Request req) async {
    final body = await req.readAsString();
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response.badRequest(body: 'Invalid JSON');
    }

    final id       = json['id'] as String? ?? _timestamp();
    final data     = json['data'] as String?;
    final mime     = json['mimeType'] as String? ?? 'image/jpeg';
    if (data == null) return Response.badRequest(body: 'Missing data');

    final ext  = mime.split('/').last.replaceAll('jpeg', 'jpg');
    final dir  = await _galleryDir();
    final file = File('${dir.path}/$id.$ext');
    await file.writeAsBytes(base64Decode(data));

    return _json({'id': '$id.$ext'});
  }

  Future<Response> _deletePhoto(Request req, String id) async {
    final dir  = await _galleryDir();
    final file = File('${dir.path}/$id');
    if (await file.exists()) await file.delete();
    return Response(204);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<Directory> _galleryDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir  = Directory('${base.path}/gallery');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
           lower.endsWith('.png') || lower.endsWith('.webp');
  }

  static String _nameOnly(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dot  = name.lastIndexOf('.');
    return dot == -1 ? name : name.substring(0, dot);
  }

  static String _timestamp() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  static Response _json(dynamic data) => Response.ok(
        jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );

  static Middleware _cors() => (handler) => (req) async {
        final res = await handler(req);
        return res.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        });
      };
}

final localServer = LocalServer();
