import 'package:flutter/material.dart';

/// 테마별 색상 토큰.
///
/// Material 3의 ColorScheme만으로는 표현되지 않는 의미 단위(보조 배경, 구분선,
/// 3단계 텍스트 위계)를 담는다. 위젯에서는 `context.colors`로 접근한다.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primaryForeground,
    required this.danger,
    required this.hot,
  });

  /// 화면 최하단 배경
  final Color background;

  /// 카드·시트 등 배경 위에 올라가는 면
  final Color surface;

  /// 입력창·비활성 칩처럼 한 단계 눌린 면
  final Color surfaceAlt;

  final Color border;

  /// 본문·제목
  final Color textPrimary;

  /// 설명 문구
  final Color textSecondary;

  /// placeholder·비활성 라벨
  final Color textTertiary;

  final Color primary;
  final Color primaryForeground;
  final Color danger;

  /// 인기·급상승 표시에 쓰는 강조색.
  /// 오류를 뜻하는 [danger]와 구분해 따로 둔다.
  final Color hot;

  /// 로고 원본(assets/logos/*.svg)이 쓰는 브랜드 컬러.
  static const brandBlue = Color(0xFF4C6EF5);

  /// 어두운 배경에서 [brandBlue]는 명도가 부족해 가라앉는다. 다크 전용 변형.
  static const brandBlueDark = Color(0xFF8DA2FF);

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF4F5F7),
    border: Color(0xFFE4E7EC),
    textPrimary: Color(0xFF13161C),
    textSecondary: Color(0xFF667085),
    textTertiary: Color(0xFF98A2B3),
    // 로고 SVG에 박혀 있는 브랜드 컬러. 로고와 UI 색이 갈리지 않도록 여기서 맞춘다.
    primary: brandBlue,
    primaryForeground: Color(0xFFFFFFFF),
    danger: Color(0xFFDC2626),
    hot: Color(0xFFF0483E),
  );

  static const dark = AppColors(
    background: Color(0xFF0F1115),
    surface: Color(0xFF161920),
    surfaceAlt: Color(0xFF1E222B),
    border: Color(0xFF2A2F3A),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFF98A2B3),
    textTertiary: Color(0xFF667085),
    primary: brandBlueDark,
    primaryForeground: Color(0xFF0F1115),
    danger: Color(0xFFF87171),
    hot: Color(0xFFFF6B5E),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primary,
    Color? primaryForeground,
    Color? danger,
    Color? hot,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      danger: danger ?? this.danger,
      hot: hot ?? this.hot,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(
        primaryForeground,
        other.primaryForeground,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      hot: Color.lerp(hot, other.hot, t)!,
    );
  }
}

/// 소셜 로그인 버튼 색상.
///
/// 각 사의 브랜드 가이드라인이 정한 값이라 앱 테마를 따르지 않는다.
/// 다만 구글·애플은 다크 모드용 변형을 별도로 규정하고 있어 이를 반영한다.
abstract final class BrandColors {
  // 카카오는 라이트/다크 구분 없이 단일 스펙이다.
  static const kakaoBackground = Color(0xFFFEE500);
  static const kakaoForeground = Color(0xD9000000); // 불투명도 85%

  static const googleLightBackground = Color(0xFFFFFFFF);
  static const googleLightForeground = Color(0xFF1F1F1F);
  static const googleLightBorder = Color(0xFF747775);

  static const googleDarkBackground = Color(0xFF131314);
  static const googleDarkForeground = Color(0xFFE3E3E3);
  static const googleDarkBorder = Color(0xFF8E918F);

  static const appleLightBackground = Color(0xFF000000);
  static const appleLightForeground = Color(0xFFFFFFFF);

  static const appleDarkBackground = Color(0xFFFFFFFF);
  static const appleDarkForeground = Color(0xFF000000);
}
