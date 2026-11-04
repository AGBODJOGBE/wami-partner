import 'package:flutter/material.dart';

import 'wami_colors.dart';

/// Couleurs sémantiques qui changent entre thème clair et sombre.
/// Accès : `context.wami.ink`, `context.wami.glass`…
@immutable
class WamiPalette extends ThemeExtension<WamiPalette> {
  const WamiPalette({
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.ink,
    required this.inkMuted,
    required this.orangeStrong,
    required this.orangeSoft,
    required this.nuitSoft,
    required this.glass,
    required this.glassBorder,
    required this.success,
    required this.danger,
    required this.focus,
    required this.sheet,
  });

  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color ink;
  final Color inkMuted;
  final Color orangeStrong;
  final Color orangeSoft;
  final Color nuitSoft;
  final Color glass;
  final Color glassBorder;
  final Color success;
  final Color danger;
  final Color focus;
  final Color sheet;

  static const dark = WamiPalette(
    surface: WamiColors.night,
    surfaceMuted: Color(0xFF141F36),
    border: Color(0xFF2A3856),
    ink: Color(0xFFF3F2EE),
    inkMuted: Color(0xFFA9B2C6),
    orangeStrong: WamiColors.orangeLight,
    orangeSoft: Color(0xFF3A2414),
    nuitSoft: Color(0xFF16223D),
    glass: Color(0x0EFFFFFF), // rgba(255,255,255,.055)
    glassBorder: Color(0x1AFFFFFF), // rgba(255,255,255,.10)
    success: WamiColors.success,
    danger: WamiColors.danger,
    focus: WamiColors.orangePeach,
    sheet: WamiColors.nightSheet,
  );

  static const light = WamiPalette(
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF3F2EE),
    border: Color(0xFFD6D5CF),
    ink: WamiColors.nuit,
    inkMuted: Color(0xFF5B6275),
    orangeStrong: WamiColors.orangeDeep,
    orangeSoft: Color(0xFFFFF0E6),
    nuitSoft: Color(0xFFE8EBF2),
    glass: Color(0x0A14213D), // rgba(20,33,61,.04)
    glassBorder: Color(0x1A14213D),
    success: WamiColors.successDeep,
    danger: WamiColors.dangerDeep,
    focus: WamiColors.nuit,
    sheet: Color(0xF5FFFFFF),
  );

  @override
  WamiPalette copyWith({
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? ink,
    Color? inkMuted,
    Color? orangeStrong,
    Color? orangeSoft,
    Color? nuitSoft,
    Color? glass,
    Color? glassBorder,
    Color? success,
    Color? danger,
    Color? focus,
    Color? sheet,
  }) {
    return WamiPalette(
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      orangeStrong: orangeStrong ?? this.orangeStrong,
      orangeSoft: orangeSoft ?? this.orangeSoft,
      nuitSoft: nuitSoft ?? this.nuitSoft,
      glass: glass ?? this.glass,
      glassBorder: glassBorder ?? this.glassBorder,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      focus: focus ?? this.focus,
      sheet: sheet ?? this.sheet,
    );
  }

  @override
  WamiPalette lerp(WamiPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return WamiPalette(
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      orangeStrong: l(orangeStrong, other.orangeStrong),
      orangeSoft: l(orangeSoft, other.orangeSoft),
      nuitSoft: l(nuitSoft, other.nuitSoft),
      glass: l(glass, other.glass),
      glassBorder: l(glassBorder, other.glassBorder),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      focus: l(focus, other.focus),
      sheet: l(sheet, other.sheet),
    );
  }
}

extension WamiPaletteX on BuildContext {
  WamiPalette get wami => Theme.of(this).extension<WamiPalette>() ?? WamiPalette.dark;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
