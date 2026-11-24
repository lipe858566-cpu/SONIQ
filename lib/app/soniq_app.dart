import 'package:flutter/material.dart';

import '../core/state/soniq_controller.dart';
import '../core/theme/soniq_theme.dart';
import '../features/shell/splash_screen.dart';

class SoniqApp extends StatelessWidget {
  const SoniqApp({super.key, required this.controller, required this.initialization});

  final SoniqController controller;
  final Future<void> initialization;

  @override
  Widget build(BuildContext context) {
    return SoniqScope(
      controller: controller,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => MaterialApp(
          title: 'SONIQ',
          debugShowCheckedModeBanner: false,
          theme: SoniqTheme.light(controller.accent),
          darkTheme: SoniqTheme.dark(controller.accent),
          themeMode: controller.themeMode,
          home: SplashScreen(initialization: initialization),
        ),
      ),
    );
  }
}
