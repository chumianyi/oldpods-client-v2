import 'package:flutter/material.dart';

/// Neumorphism（新拟态）调色板
class NeuPalette {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color shadowLight;
  final Color shadowDark;
  final Color text;
  final Color subText;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color danger;
  final Color success;
  final Color warning;
  final Color divider;

  const NeuPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.shadowLight,
    required this.shadowDark,
    required this.text,
    required this.subText,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.danger,
    required this.success,
    required this.warning,
    required this.divider,
  });

  static const NeuPalette lightPalette = NeuPalette(
    bg: Color(0xFFF7F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0F2ED),
    shadowLight: Color(0xFFFFFFFF),
    shadowDark: Color(0xFFB7C8BE),
    text: Color(0xFF203A31),
    subText: Color(0xFF607269),
    accent: Color(0xFF18705B),
    accentSoft: Color(0xFFE1EFE7),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFE5544F),
    success: Color(0xFF3E9E68),
    warning: Color(0xFFE39B2D),
    divider: Color(0xFFDDE4DC),
  );

  static const NeuPalette darkPalette = NeuPalette(
    bg: Color(0xFF121D1A),
    surface: Color(0xFF1A2B24),
    surfaceAlt: Color(0xFF22352D),
    shadowLight: Color(0xFF30463A),
    shadowDark: Color(0xFF09120D),
    text: Color(0xFFE8F1EB),
    subText: Color(0xFFACBEB2),
    accent: Color(0xFF88D6B0),
    accentSoft: Color(0xFF244F3B),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFF06A68),
    success: Color(0xFF4FBC7C),
    warning: Color(0xFFEFB25E),
    divider: Color(0xFF30463A),
  );

  static NeuPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkPalette : lightPalette;
}

/// Neumorphism 主题
class NeuTheme {
  static ThemeData light() => _base(NeuPalette.lightPalette, Brightness.light);

  static ThemeData dark() => _base(NeuPalette.darkPalette, Brightness.dark);

  static ThemeData _base(NeuPalette p, Brightness b) {
    final base = ThemeData(
      brightness: b,
      useMaterial3: true,
      fontFamily: 'LXGW WenKai',
      primaryColor: p.accent,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      cardColor: p.surface,
      dividerColor: p.divider,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: p.accent,
        secondary: p.accent,
        surface: p.surface,
        error: p.danger,
        onPrimary: b == Brightness.dark ? p.bg : p.onAccent,
        onSurface: p.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: 'LXGW WenKai', height: 1.45, letterSpacing: 0.3, color: p.text, fontSize: 18, fontWeight: FontWeight.w300),
        iconTheme: IconThemeData(color: p.text),
      ),
      textTheme: base.textTheme.apply(fontFamily: 'LXGW WenKai').copyWith(
        headlineSmall: TextStyle(fontFamily: 'LXGW WenKai', height: 1.45, letterSpacing: 0.3, color: p.text, fontSize: 22, fontWeight: FontWeight.w300),
        titleLarge: TextStyle(fontFamily: 'LXGW WenKai', height: 1.45, letterSpacing: 0.3, color: p.text, fontSize: 18, fontWeight: FontWeight.w300),
        titleMedium: TextStyle(fontFamily: 'LXGW WenKai', height: 1.45, letterSpacing: 0.3, color: p.text, fontSize: 16, fontWeight: FontWeight.w300),
        bodyLarge: TextStyle(fontFamily: 'LXGW WenKai', height: 1.45, letterSpacing: 0.3, color: p.text, fontSize: 15),
        bodyMedium: TextStyle(fontFamily: 'LXGW WenKai', height: 1.45, letterSpacing: 0.3, color: p.text, fontSize: 13.5),
        bodySmall: TextStyle(fontFamily: 'LXGW WenKai', height: 1.45, letterSpacing: 0.3, color: p.subText, fontSize: 12),
        labelLarge: TextStyle(fontFamily: 'LXGW WenKai', height: 1.45, letterSpacing: 0.3, color: p.text, fontSize: 14, fontWeight: FontWeight.w300),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.text,
        contentTextStyle: TextStyle(fontFamily: 'LXGW WenKai', height: 1.45, letterSpacing: 0.3, color: p.bg, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent, linearTrackColor: p.shadowDark),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: p.text, borderRadius: BorderRadius.circular(8)),
        textStyle: TextStyle(fontFamily: 'LXGW WenKai', height: 1.45, letterSpacing: 0.3, color: p.bg, fontSize: 12),
      ),
    );
  }
}
