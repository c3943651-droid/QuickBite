import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.quickbiteOrange,
      primary: AppColors.quickbiteOrange,
      secondary: AppColors.appetiteRed,
      tertiary: AppColors.energyYellow,
      surface: AppColors.white,
      error: AppColors.errorRed,
    );

    return _base(colorScheme).copyWith(
      scaffoldBackgroundColor: AppColors.mistGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textGray,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: _textTheme(AppColors.textGray, AppColors.secondaryGray),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.quickbiteOrange,
      brightness: Brightness.dark,
      primary: AppColors.quickbiteOrange,
      secondary: AppColors.appetiteRed,
      tertiary: AppColors.energyYellow,
      surface: AppColors.darkSurface,
      error: AppColors.errorRed,
    );

    return _base(colorScheme).copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: _textTheme(AppColors.darkTextPrimary, AppColors.secondaryGray),
    );
  }

  static ThemeData _base(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppTextStyles.fontFamily,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: _border(colorScheme.outlineVariant),
        enabledBorder: _border(colorScheme.outlineVariant),
        focusedBorder: _border(AppColors.quickbiteOrange, width: 2),
        errorBorder: _border(AppColors.errorRed),
        focusedErrorBorder: _border(AppColors.errorRed, width: 2),
        errorStyle: AppTextStyles.label.copyWith(color: AppColors.errorRed),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          backgroundColor: AppColors.quickbiteOrange,
          foregroundColor: AppColors.white,
          textStyle: AppTextStyles.label.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          foregroundColor: AppColors.quickbiteOrange,
          side: const BorderSide(color: AppColors.quickbiteOrange, width: 2),
          textStyle: AppTextStyles.label.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        labelStyle: AppTextStyles.label.copyWith(color: colorScheme.onSurface),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1F000000),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: AppTextStyles.display.copyWith(color: primary),
      headlineLarge: AppTextStyles.headline1.copyWith(color: primary),
      headlineMedium: AppTextStyles.headline2.copyWith(color: primary),
      titleLarge: AppTextStyles.title.copyWith(color: primary),
      titleMedium: AppTextStyles.title.copyWith(fontSize: 16, color: primary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: secondary),
      labelLarge: AppTextStyles.label.copyWith(fontSize: 16, color: primary),
      labelMedium: AppTextStyles.label.copyWith(color: secondary),
      labelSmall: AppTextStyles.caption.copyWith(color: secondary),
    );
  }
}
