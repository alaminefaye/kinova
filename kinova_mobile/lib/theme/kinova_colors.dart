import 'package:flutter/material.dart';

/// Palette raffinée extraite et sublimée du logo KINOVA
class KinovaColors {
  KinovaColors._();

  /// Fond principal du logo (#F0DBCA)
  static const Color background = Color(0xFFF8F2EC);

  /// Beige moyen / ombre douce
  static const Color sand = Color(0xFFC1A895);

  /// Or métallique du monogramme K
  static const Color gold = Color(0xFFC5A080);

  /// Or riche pour accents
  static const Color goldRich = Color(0xFFD4AF37);

  /// Or doux clair
  static const Color goldLight = Color(0xFFE8D7C8);

  /// Brun chocolat du wordmark
  static const Color brown = Color(0xFF3E2723);

  /// Brun secondaire (feuilles)
  static const Color mutedBrown = Color(0xFFA88F80);

  /// Crème claire (highlights)
  static const Color cream = Color(0xFFFDFBF7);

  /// Surface claire pour cartes / panneaux
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface secondaire légèrement teintée
  static const Color surfaceMuted = Color(0xFFFAF4EE);

  /// Ombre portée douce pour cartes
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: brown.withValues(alpha: 0.07),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: gold.withValues(alpha: 0.05),
          blurRadius: 8,
          spreadRadius: -2,
          offset: const Offset(0, 2),
        ),
      ];

  /// Ombre subtile pour éléments interactifs
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: brown.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  /// Dégradé Or Signature
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4AF37),
      Color(0xFFC5A080),
      Color(0xFFE8D5B7),
    ],
  );

  /// Dégradé somptueux sombre (Chocolat / Or)
  static const LinearGradient darkLuxuryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3E2723),
      Color(0xFF251614),
    ],
  );
}

