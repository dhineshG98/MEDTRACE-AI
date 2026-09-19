import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // Univers 73px 700 0.92 0 Aa Bb Cc
  static TextStyle universTitle({
    double fontSize = 73,
    FontWeight fontWeight = FontWeight.w700,
    double height = 0.92,
    double letterSpacing = 0.0,
    Color color = AppColors.textPrimary,
  }) {
    return TextStyle(
      fontFamily: 'Univers',
      fontFamilyFallback: const [
        'UniversLTStd',
        'Univers 55',
        'Helvetica Neue',
        'Helvetica',
        'Arial',
        'sans-serif',
      ],
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // h3 Libre Franklin 20px 700 1.4 0 Aa Bb Cc
  static TextStyle h3({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.4,
    double letterSpacing = 0.0,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.libreFranklin(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // body Libre Franklin 18px 400 1.4 0 Aa Bb Cc
  static TextStyle body({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.4,
    double letterSpacing = 0.0,
    Color color = AppColors.textSecondary,
  }) {
    return GoogleFonts.libreFranklin(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // button helvetica 14px 400 1.75 0 Aa Bb Cc
  static TextStyle button({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.75,
    double letterSpacing = 0.0,
    Color color = Colors.white,
  }) {
    return TextStyle(
      fontFamily: 'Helvetica',
      fontFamilyFallback: const [
        'Helvetica Neue',
        'Arial',
        'sans-serif',
      ],
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.libreFranklinTextTheme(baseTextTheme).copyWith(
      displayLarge: universTitle(
        fontSize: 73,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
        height: 0.92,
        color: AppColors.textPrimary,
      ),
      displayMedium: universTitle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
        height: 0.95,
        color: AppColors.textPrimary,
      ),
      headlineMedium: h3(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      titleLarge: h3(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      titleMedium: h3(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      bodyLarge: body(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.4,
        color: AppColors.textSecondary,
      ),
      bodyMedium: body(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.4,
        color: AppColors.textSecondary,
      ),
      labelMedium: button(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.75,
        color: AppColors.textMuted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.indigo,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.borderMedium),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.textPrimary,
        ),
        waitDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
