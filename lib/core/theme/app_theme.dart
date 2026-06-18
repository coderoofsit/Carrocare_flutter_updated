import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final textTheme = AppTypography.textTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.primaryLight,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.grey800,
        error: AppColors.primaryDark,
      ),
      scaffoldBackgroundColor: AppColors.white,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.grey800,
        titleTextStyle: AppTypography.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.grey800,
        ),
        iconTheme: const IconThemeData(color: AppColors.grey800),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          side: const BorderSide(color: AppColors.grey200),
        ),
        shadowColor: AppColors.shadowLight,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.grey300,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey50,
        hintStyle: AppTypography.dmSans(
          fontSize: 14,
          color: AppColors.grey500,
        ),
        labelStyle: AppTypography.dmSans(
          fontSize: 14,
          color: AppColors.grey600,
        ),
        border: AppDecorations.inputBorder(),
        enabledBorder: AppDecorations.inputBorder(),
        focusedBorder: AppDecorations.inputBorder(focused: true),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
          ),
          textStyle: GoogleFonts.quicksand(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey500,
        selectedLabelStyle: GoogleFonts.quicksand(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.grey300,
        ),
        side: const BorderSide(color: AppColors.grey400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey800,
        contentTextStyle: AppTypography.dmSans(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.inputRadius),
        ),
      ),
    );
  }
}
