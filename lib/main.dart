import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/local_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start local HTTP server for companion app photo uploads (port 8080)
  await localServer.start();

  // Lock to portrait — circular display has no meaningful landscape mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Kiosk / immersive mode — hides system UI; also respected by flutter-pi
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    // ProviderScope is the Riverpod root — must wrap the entire app
    const ProviderScope(child: CircleHubApp()),
  );
}
