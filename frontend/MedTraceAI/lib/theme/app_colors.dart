import 'package:flutter/material.dart';

/// Modern dark-theme color tokens with clinical AI accents
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D11);
  static const Color surfaceElevated = Color(0xFF141418);
  static const Color surfaceHover = Color(0xFF1C1C22);
  static const Color glassBackground = Color(0xE60D0D11);
  static const Color glassCard = Color(0x99141418);
  static const Color glassCardHover = Color(0xD91C1C22);

  // Borders & Dividers (Monochrome)
  static const Color borderSubtle = Color(0x26FFFFFF);
  static const Color borderMedium = Color(0x40FFFFFF);
  static const Color borderHighlight = Color(0x73FFFFFF);
  static const Color borderGlow = Color(0x33FFFFFF);
  static const Color borderEmerald = Color(0x33FFFFFF);

  // Monochrome & Contrast Accents
  static const Color cyan = Colors.white;
  static const Color cyanNeon = Colors.white;
  static const Color cyanGlow = Color(0x33FFFFFF);
  static const Color indigo = Color(0xFFD4D4D8);
  static const Color purple = Color(0xFFE4E4E7);
  static const Color emerald = Color(0xFFF4F4F5);
  static const Color emeraldNeon = Colors.white;
  static const Color amber = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFFB7185);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  // Status indicators
  static const Color statusOnline = Colors.white;
  static const Color statusBusy = Color(0xFFF59E0B);

  // Gradients (Pure Monochrome)
  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFE2E8F0),
      Color(0xFFCBD5E1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanEmeraldGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient indigoCyanGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFCBD5E1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlassGradient = LinearGradient(
    colors: [
      Color(0x14FFFFFF),
      Color(0x05141418),
      Color(0x26000000),
    ],
    stops: [0.0, 0.45, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
