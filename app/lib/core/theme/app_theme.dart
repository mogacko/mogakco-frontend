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
      // 칸마다 상자를 두르지 않고 밑줄만 긋는다. 등록 화면처럼 칸이 여럿
      // 이어지는 곳에서 상자를 쌓으면 화면이 격자로 덮여, 정작 읽어야 할
      // 라벨과 적어 넣은 글이 테두리에 묻힌다.
      //
      // 가로 여백도 없앤다. 밑줄 방식에서는 글자가 위 라벨과 같은 선에서
      // 시작해야 한 덩어리로 읽힌다.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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

  static UnderlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return UnderlineInputBorder(
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

extension BorderlessInput on InputDecoration {
  /// 여러 줄을 길게 받는 칸에서 밑줄을 걷어낸다.
  ///
  /// 여덟 줄짜리 본문 칸에 밑줄을 그으면 선이 저 아래 홀로 떠서 무엇에
  /// 붙은 선인지 읽히지 않는다. 라벨이 이미 자리를 알려주므로 없어도 된다.
  InputDecoration get borderless => copyWith(
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
  );
}

extension AppThemeContext on BuildContext {
  /// 테마 색상 토큰 단축 접근자.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  TextTheme get texts => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
