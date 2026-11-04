import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// Typographie : Unbounded pour les titres de marque et les chiffres,
/// DM Sans pour le texte d'interface.
abstract final class WamiTypography {
  // Polices déclarées par le paquet wami_core : le nom de famille est préfixé.
  static const display = 'packages/wami_core/Unbounded';
  static const sans = 'packages/wami_core/DMSans';

  static TextTheme textTheme(Color ink, Color inkMuted) {
    return TextTheme(
      // display-xl / display-lg / display-sm
      displayLarge: TextStyle(fontFamily: display, fontSize: 48, height: 52 / 48, fontWeight: FontWeight.w700, letterSpacing: -1.44, color: ink),
      displayMedium: TextStyle(fontFamily: display, fontSize: 32, height: 38 / 32, fontWeight: FontWeight.w700, letterSpacing: -0.64, color: ink),
      displaySmall: TextStyle(fontFamily: display, fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700, letterSpacing: -0.22, color: ink),
      // Titre d'écran futuriste (21 px).
      headlineSmall: TextStyle(fontFamily: display, fontSize: 21, height: 1.25, fontWeight: FontWeight.w700, letterSpacing: -0.42, color: ink),
      // heading
      titleLarge: TextStyle(fontFamily: sans, fontSize: 20, height: 26 / 20, fontWeight: FontWeight.w700, color: ink),
      titleMedium: TextStyle(fontFamily: sans, fontSize: 16, height: 1.35, fontWeight: FontWeight.w700, color: ink),
      titleSmall: TextStyle(fontFamily: sans, fontSize: 14, height: 1.35, fontWeight: FontWeight.w700, color: ink),
      // body-lg / body
      bodyLarge: TextStyle(fontFamily: sans, fontSize: 17, height: 24 / 17, fontWeight: FontWeight.w400, color: ink),
      bodyMedium: TextStyle(fontFamily: sans, fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400, color: ink),
      // Texte secondaire (12,5 px muted).
      bodySmall: TextStyle(fontFamily: sans, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w400, color: inkMuted),
      // label
      labelLarge: TextStyle(fontFamily: sans, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600, color: ink),
      // caption
      labelMedium: TextStyle(fontFamily: sans, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500, color: ink),
      // Sur-titre de section en capitales.
      labelSmall: TextStyle(fontFamily: sans, fontSize: 10.5, height: 1.3, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: inkMuted),
    );
  }

  /// Chiffres (prix, compteurs, heures) en Unbounded.
  static TextStyle number(double size, {Color? color, FontWeight weight = FontWeight.w700}) {
    return TextStyle(
      fontFamily: display,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: -0.02 * size,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
