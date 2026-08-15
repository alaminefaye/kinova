import 'package:flutter/material.dart';
import 'package:kinova_mobile/theme/kinova_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: KinovaColors.brown,
      onPrimary: KinovaColors.cream,
      secondary: KinovaColors.gold,
      onSecondary: KinovaColors.brown,
      surface: KinovaColors.surface,
      onSurface: KinovaColors.brown,
      outline: KinovaColors.sand,
    );

    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'PlayfairDisplay',
        color: KinovaColors.brown,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
      displayMedium: TextStyle(
        fontFamily: 'PlayfairDisplay',
        color: KinovaColors.brown,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'PlayfairDisplay',
        color: KinovaColors.brown,
        fontWeight: FontWeight.w600,
        fontSize: 26,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'PlayfairDisplay',
        color: KinovaColors.brown,
        fontWeight: FontWeight.w600,
        fontSize: 22,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Montserrat',
        color: KinovaColors.brown,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Montserrat',
        color: KinovaColors.brown,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Montserrat',
        color: KinovaColors.brown,
        fontSize: 15,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Montserrat',
        color: KinovaColors.mutedBrown,
        fontSize: 13,
        height: 1.45,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Montserrat',
        color: KinovaColors.brown,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KinovaColors.background,
      textTheme: textTheme,
      fontFamily: 'Montserrat',
      appBarTheme: const AppBarTheme(
        backgroundColor: KinovaColors.background,
        foregroundColor: KinovaColors.brown,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: KinovaColors.brown,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KinovaColors.brown,
          foregroundColor: KinovaColors.cream,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KinovaColors.brown,
          side: const BorderSide(color: KinovaColors.gold, width: 1.2),
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KinovaColors.surface,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          color: KinovaColors.mutedBrown.withValues(alpha: 0.7),
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: KinovaColors.gold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: KinovaColors.sand.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: KinovaColors.gold,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: KinovaColors.surface,
        selectedItemColor: KinovaColors.brown,
        unselectedItemColor: KinovaColors.mutedBrown,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: KinovaColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: KinovaColors.gold.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
    );
  }
}
