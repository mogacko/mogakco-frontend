import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final textTheme = _textTheme(c);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: c.primary,
            brightness: brightness,
          ).copyWith(
            primary: c.primary,
            onPrimary: c.primaryForeground,
            surface: c.surface,
            onSurface: c.textPrimary,
            error: c.danger,
            outline: c.border,
          ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(color: c.textPrimary),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryForeground,
          disabledBackgroundColor: c.surfaceAlt,
          disabledForegroundColor: c.textTertiary,
          minimumSize: const Size.fromHeight(AppSize.buttonHeight),
          textStyle: AppTypography.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.textSecondary,
          textStyle: AppTypography.labelMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: AppTypography.bodyLarge.copyWith(color: c.textTertiary),
        border: _inputBorder(c.border),
        enabledBorder: _inputBorder(c.border),
        focusedBorder: _inputBorder(c.primary, width: 1.5),
        errorBorder: _inputBorder(c.danger),
        focusedErrorBorder: _inputBorder(c.danger, width: 1.5),
        errorStyle: AppTypography.caption.copyWith(color: c.danger),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? c.primary
              : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(c.primaryForeground),
        side: BorderSide(color: c.border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm / 2),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.textPrimary,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: c.background,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(AppColors c) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: c.textPrimary),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: c.textPrimary),
      headlineMedium: AppTypography.headlineMedium.copyWith(
        color: c.textPrimary,
      ),
      titleLarge: AppTypography.titleLarge.copyWith(color: c.textPrimary),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: c.textPrimary),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: c.textSecondary),
      labelLarge: AppTypography.labelLarge.copyWith(color: c.textPrimary),
      labelMedium: AppTypography.labelMedium.copyWith(color: c.textSecondary),
      labelSmall: AppTypography.caption.copyWith(color: c.textTertiary),
    );
  }
}

extension AppThemeContext on BuildContext {
  /// 테마 색상 토큰 단축 접근자.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  TextTheme get texts => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
