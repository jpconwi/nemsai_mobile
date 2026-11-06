import 'package:flutter/material.dart';

/// Colours copied from the website's app.css (the new blue palette).
class C {
  static const blue = Color(0xFF246BB4);
  static const blueDeep = Color(0xFF104B98);
  static const blueSoft = Color(0xFFEDF4FC);
  static const gold = Color(0xFF5F91C7);
  static const paper = Color(0xFFF4F6F9);
  static const line = Color(0xFFD6DEE8);
  static const ink = Color(0xFF182F49);
  static const muted = Color(0xFF5A6F84);
  static const error = Color(0xFFB3121C);
  static const okBg = Color(0xFFEEF8EF);
  static const okLine = Color(0xFFB8DCB9);
  static const skBase = Color(0xFFE3EAF2);
  static const skHigh = Color(0xFFF5F8FB);
}

const serif = 'serif';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: C.blue, primary: C.blue, secondary: C.gold);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: C.blueDeep,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: serif, fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.blue, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: C.error, width: 1.6)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.blue,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: C.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );
}
