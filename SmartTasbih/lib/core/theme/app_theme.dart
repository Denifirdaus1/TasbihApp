import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(),
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.emerald,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.seed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: AppColors.seed.withValues(alpha: .15),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
