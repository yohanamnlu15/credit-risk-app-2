import 'package:flutter/material.dart';

class AppColors {
  static const Color navyPrimary = Color(0xFF0A2647);
  static const Color accentBlue = Color(0xFF205295);
  static const Color background = Color(0xFFF4F6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color greyLight = Color(0xFFE4E8EE);
  static const Color greyMedium = Color(0xFF8A94A6);
  static const Color textPrimary = Color(0xFF1B2A41);
  static const Color textSecondary = Color(0xFF5B6B79);
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE6F4EA);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerBg = Color(0xFFFDECEA);

  AppColors._();
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.navyPrimary,
      brightness: Brightness.light,
    );

    final colorScheme = baseScheme.copyWith(
      primary: AppColors.navyPrimary,
      secondary: AppColors.accentBlue,
      error: AppColors.danger,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.navyPrimary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navyPrimary,
          side: const BorderSide(color: AppColors.navyPrimary, width: 1.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.navyPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.greyLight.withOpacity(0.55),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.greyLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyPrimary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: TextStyle(color: AppColors.greyMedium),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.greyLight, thickness: 1),
    );
  }
}