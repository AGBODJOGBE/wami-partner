import 'package:flutter/material.dart';

/// Couleurs de marque, fixes quel que soit le thème.
/// Source : tokens.json du design system WAMI.
abstract final class WamiColors {
  // Orange — couleur principale.
  static const orange = Color(0xFFF25C05);
  static const orangeLight = Color(0xFFFF7A2E);
  static const orangeMid = Color(0xFFE04E00);
  static const orangeDeep = Color(0xFFC94A00);
  static const orangePeach = Color(0xFFFFD3B0);

  // Bleu nuit — couleur secondaire.
  static const nuit = Color(0xFF14213D);
  static const nuitLight = Color(0xFF33497D);
  static const nuitDark = Color(0xFF0B1427);

  // Fond futuriste.
  static const night = Color(0xFF070D1A);
  static const nightSheet = Color(0xF009101F);
  static const map = Color(0xFF0A1326);
  static const mapBlock = Color(0xFF0D1931);
  static const mapRoad = Color(0xFF17274B);
  static const mapLane = Color(0xFF101C35);

  // Texte toujours blanc sur orange (règle validée : 16 px gras minimum).
  static const onPrimary = Color(0xFFFFFFFF);
  static const white = Color(0xFFFFFFFF);

  // Lueurs par univers de service.
  static const glowMobilite = Color(0xFFF25C05);
  static const glowLivraison = Color(0xFF5A82E6);
  static const glowBus = Color(0xFF50C8BE);
  static const glowHebergement = Color(0xFFFFBE78);

  // Statuts.
  static const success = Color(0xFF3DBE7E);
  static const successDeep = Color(0xFF1F7A4D);
  static const danger = Color(0xFFFF6B6B);
  static const dangerDeep = Color(0xFFC62828);
  static const star = Color(0xFFFFC58F);
}
