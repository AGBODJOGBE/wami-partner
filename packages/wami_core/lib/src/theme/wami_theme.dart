import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'wami_colors.dart';
import 'wami_palette.dart';
import 'wami_tokens.dart';
import 'wami_typography.dart';

/// Thèmes Material construits à partir des tokens WAMI.
/// Le thème sombre est la direction futuriste validée ; le clair reste disponible.
abstract final class WamiTheme {
  static ThemeData dark() => _build(Brightness.dark, WamiPalette.dark);
  static ThemeData light() => _build(Brightness.light, WamiPalette.light);

  static ThemeData _build(Brightness brightness, WamiPalette p) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: WamiColors.orange,
      onPrimary: WamiColors.onPrimary,
      secondary: isDark ? const Color(0xFF1E2F55) : WamiColors.nuit,
      onSecondary: WamiColors.white,
      error: p.danger,
      onError: WamiColors.white,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.inkMuted,
      outline: p.border,
      surfaceContainerHighest: p.surfaceMuted,
    );
    final text = WamiTypography.textTheme(p.ink, p.inkMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.surface,
      fontFamily: WamiTypography.sans,
      textTheme: text,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: p.ink,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      dividerTheme: DividerThemeData(color: p.glassBorder, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.glass,
        hintStyle: text.bodyMedium?.copyWith(color: p.inkMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: WamiColors.orangeLight, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF141F36) : WamiColors.nuit,
        contentTextStyle: text.labelLarge?.copyWith(color: WamiColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(WamiRadius.md)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
