import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

const String _latinFontFamily = 'Inter';
const List<String> _fontFallback = <String>['NotoSansSC'];

FThemeData buildForuiTheme({required Brightness brightness}) {
  final bool isDark = brightness == Brightness.dark;
  final FColors colors = isDark ? _darkColors() : _lightColors();
  final FTypography typography = _buildTypography(colors);
  final FStyle style = _buildStyle(colors, typography);

  return FThemeData(
    debugLabel: isDark ? 'SpeakSense Dark' : 'SpeakSense Light',
    colors: colors,
    typography: typography,
    style: style,
  );
}

FColors _lightColors() {
  return const FColors(
    brightness: Brightness.light,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    barrier: Color(0x33000000),
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF0F172A),
    primary: Color(0xFF2962FF),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFE2E8F0),
    secondaryForeground: Color(0xFF0F172A),
    muted: Color(0xFFF1F5F9),
    mutedForeground: Color(0xFF64748B),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFFFFFF),
    error: Color(0xFFEF4444),
    errorForeground: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
  );
}

FColors _darkColors() {
  return const FColors(
    brightness: Brightness.dark,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    barrier: Color(0x7A000000),
    background: Color(0xFF0F1423),
    foreground: Color(0xFFF9FAFB),
    primary: Color(0xFF2962FF),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF1F2937),
    secondaryForeground: Color(0xFFF9FAFB),
    muted: Color(0xFF1F2937),
    mutedForeground: Color(0xFF94A3B8),
    destructive: Color(0xFF7F1D1D),
    destructiveForeground: Color(0xFFF9FAFB),
    error: Color(0xFF7F1D1D),
    errorForeground: Color(0xFFF9FAFB),
    border: Color(0xFF1F2937),
  );
}

FTypography _buildTypography(FColors colors) {
  return FTypography(
    defaultFontFamily: _latinFontFamily,
    xs: _textStyle(colors: colors, size: 12, height: 1),
    sm: _textStyle(colors: colors, size: 14, height: 1.25),
    base: _textStyle(colors: colors, size: 16, height: 1.5),
    lg: _textStyle(colors: colors, size: 18, height: 1.75),
    xl: _textStyle(colors: colors, size: 20, height: 1.75),
    xl2: _textStyle(colors: colors, size: 22, height: 2),
    xl3: _textStyle(colors: colors, size: 30, height: 2.25),
    xl4: _textStyle(colors: colors, size: 36, height: 2.5),
    xl5: _textStyle(colors: colors, size: 48, height: 1),
    xl6: _textStyle(colors: colors, size: 60, height: 1),
    xl7: _textStyle(colors: colors, size: 72, height: 1),
    xl8: _textStyle(colors: colors, size: 96, height: 1),
  );
}

TextStyle _textStyle({
  required FColors colors,
  required double size,
  required double height,
}) {
  return TextStyle(
    color: colors.foreground,
    fontFamily: _latinFontFamily,
    fontFamilyFallback: _fontFallback,
    fontSize: size,
    height: height,
  );
}

FStyle _buildStyle(FColors colors, FTypography typography) {
  return FStyle(
    formFieldStyle: FFormFieldStyle.inherit(
      colors: colors,
      typography: typography,
    ),
    focusedOutlineStyle: FFocusedOutlineStyle(
      color: colors.primary,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
    iconStyle: IconThemeData(color: colors.primary, size: 20),
    tappableStyle: FTappableStyle(),
    borderRadius: const FLerpBorderRadius.all(Radius.circular(12), min: 24),
    borderWidth: 1,
    pagePadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    shadow: const <BoxShadow>[
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 6),
        blurRadius: 18,
      ),
    ],
  );
}
