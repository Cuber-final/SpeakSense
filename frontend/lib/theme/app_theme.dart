class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF2962FF),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF5C92FF),
        onPrimaryContainer: const Color(0xFF001C5F8),
        secondary: const Color(0xFF64748B),
        onSecondary: Colors.white,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF0F172A),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      cardTheme: const CardThemeData(elevation: 1),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        centerTitle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF2962FF),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF5C92FF),
        onPrimaryContainer: const Color(0xFF0039CB),
        secondary: const Color(0xFF64748B),
        onSecondary: Colors.white,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: const Color(0xFF0F1423),
        onSurface: const Color(0xFFF9FAFB),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1423),
      cardTheme: const CardThemeData(elevation: 1, color: Color(0xFF151922)),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFF9FAFB),
        centerTitle: true,
      ),
    );
  }

  AppTheme._();
}
