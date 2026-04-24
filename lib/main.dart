import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — circular display has no meaningful landscape mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Kiosk / immersive mode — hides system UI; also respected by flutter-pi
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    // ProviderScope is the Riverpod root — must wrap the entire app
    const ProviderScope(child: CircleHubApp()),
  );
}
