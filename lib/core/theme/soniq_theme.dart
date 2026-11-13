import 'package:flutter/material.dart';

class SoniqColors {
  static const background = Color(0xFF080611);
  static const surface = Color(0xFF1A1229);
  static const purple = Color(0xFFC20AFF);
  static const violet = Color(0xFF8A14FF);
  static const cyan = Color(0xFF09DCF5);
  static const muted = Color(0xFFB6ADC9);
  static const white = Color(0xFFF9F7FF);

  static const accents = [
    Color(0xFFC20AFF),
    Color(0xFF2673FF),
    Color(0xFF00CBEA),
    Color(0xFFFF3B99),
    Color(0xFFFF970F),
    Color(0xFF17D66A),
  ];
}

class SoniqTheme {
  static ThemeData dark(Color accent) => _build(accent, Brightness.dark);
  static ThemeData light(Color accent) => _build(accent, Brightness.light);

  static ThemeData _build(Color accent, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      primary: accent,
      surface: dark ? SoniqColors.surface : const Color(0xFFF5EEFF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? SoniqColors.background : const Color(0xFFF5F0FA),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: const Color(0xFFFFF8FF),
        inactiveTrackColor: accent.withOpacity(.25),
        overlayColor: accent.withOpacity(.16),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xD7241A36) : const Color(0xFFF1E8FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        hintStyle: TextStyle(color: dark ? Colors.white54 : Colors.black45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent.withOpacity(.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent.withOpacity(.16)),
        ),
      ),
    );
  }
}
