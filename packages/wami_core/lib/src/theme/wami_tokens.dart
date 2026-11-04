import 'package:flutter/material.dart';

import 'wami_colors.dart';

/// Espacements (tokens space-1 … space-8).
abstract final class WamiSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 24.0;
  static const s6 = 32.0;
  static const s7 = 48.0;
  static const s8 = 64.0;

  /// Marge latérale des écrans.
  static const screen = 20.0;
}

/// Rayons (tokens radius-sm … radius-pill) + rayons futuristes.
abstract final class WamiRadius {
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;

  static const card = 22.0;
  static const cta = 18.0;
  static const sheet = 30.0;
}

/// Dégradés et ombres de la direction futuriste.
abstract final class WamiEffects {
  /// Bouton principal : orange clair → orange profond, texte blanc.
  static const ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [WamiColors.orangeLight, WamiColors.orangeMid, WamiColors.orangeDeep],
    stops: [0, 0.55, 1],
  );

  static const selectedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0x38F25C05), Color(0x08F25C05)],
  );

  static List<BoxShadow> glow([Color color = WamiColors.orange, double strength = 1]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.40 * strength),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> halo([Color color = WamiColors.orange]) => [
        BoxShadow(color: color.withValues(alpha: 0.15), spreadRadius: 5),
        BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 22),
      ];

  static const glassBlur = 16.0;
}

/// Durées d'animation.
abstract final class WamiMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 350);
  static const curve = Curves.easeOutCubic;
}
