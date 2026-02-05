import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const String _latinFontFamily = 'Inter';
  static const List<String> _fontFallback = <String>['NotoSansSC'];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _latinFontFamily,
      fontFamilyFallback: _fontFallback,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2962FF),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF5C92FF),
        onPrimaryContainer: Color(0xFF001C5F),
        secondary: Color(0xFF64748B),
        onSecondary: Colors.white,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF0F172A),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      cardTheme: const CardThemeData(elevation: 1),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF0F172A),
        centerTitle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _latinFontFamily,
      fontFamilyFallback: _fontFallback,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2962FF),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF5C92FF),
        onPrimaryContainer: Color(0xFF0039CB),
        secondary: Color(0xFF64748B),
        onSecondary: Colors.white,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        surface: Color(0xFF0F1423),
        onSurface: Color(0xFFF9FAFB),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1423),
      cardTheme: const CardThemeData(elevation: 1, color: Color(0xFF151922)),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF9FAFB),
        centerTitle: true,
      ),
    );
  }
}
