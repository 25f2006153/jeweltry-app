import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFFAF6EE);
  static const Color backgroundLight = Color(0xFFFFFDF9);
  static const Color surface = Color(0xFFFFFFFF);

  // Deep Burgundy / Wine Accent
  static const Color burgundy = Color(0xFF6B1D38);
  static const Color burgundyDark = Color(0xFF4A1225);
  static const Color burgundyLight = Color(0xFF8C2B4E);
  static const Color burgundySurface = Color(0xFFF9F0F3);

  // Gold Accents
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE6C687);
  static const Color goldDark = Color(0xFFB8860B);
  static const Color goldGradientStart = Color(0xFFE5C158);
  static const Color goldGradientEnd = Color(0xFFB38928);

  // Text & Neutrals
  static const Color textDark = Color(0xFF1F1A1C);
  static const Color textMuted = Color(0xFF6E6A6C);
  static const Color border = Color(0xFFEFE8DE);
  static const Color shadow = Color(0x0F4A1225);

  // Status
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFC0392B);

  // Luxury Gradients
  static const LinearGradient burgundyGradient = LinearGradient(
    colors: [burgundy, burgundyDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldGradientStart, goldGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
