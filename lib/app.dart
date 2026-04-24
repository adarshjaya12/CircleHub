import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/splash/splash_screen.dart';

class CircleHubApp extends StatelessWidget {
  const CircleHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circle Hub',
      theme: CircleHubTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
