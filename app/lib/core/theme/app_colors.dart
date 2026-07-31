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
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primaryForeground,
    required this.danger,
    required this.hot,
  });

  /// 화면 바탕.
  ///
  /// 라이트에서도 순백이 아니다. 카드까지 흰색이면 둘이 붙어 보여서 무엇이
  /// 떠 있는 것인지 구분되지 않는다. 한 단계 낮춰 깔아야 위에 올린 것이 뜬다.
  final Color background;

  /// 바탕 위로 떠오르는 면. 카드·시트·메뉴.
  final Color surface;

  /// 카드 안에서 한 단계 눌린 면. 입력창·비활성 칩·달력 칸.
  ///
  /// 라이트에서는 카드보다 어둡고 다크에서는 밝다. 어느 쪽이든 카드에서
  /// 물러나 보이는 방향이다.
  final Color surfaceAlt;

  final Color border;

  /// 카드 테두리.
  ///
  /// 라이트에서는 투명하다. 흰 카드가 옅은 회색 바탕 위에서 이미 떠 보이고,
  /// 카드가 세로로 쌓이는 자리에 선을 두르면 층층이 겹쳐 사나워진다.
  ///
  /// 다크에서는 보인다. 어두운 쪽에서는 명도 차이만으로 경계가 잡히지 않는다.
  /// 라이트의 카드/바탕 대비는 1.08:1 인데도 잘 보이지만, 같은 1.12:1 를 다크에
  /// 두면 두 면이 붙어 보인다. 밝은 쪽에서는 눈이 미세한 차이를 잘 가리고
  /// 어두운 쪽에서는 못 가려서다. 그래서 선으로 긋는다.
  final Color cardBorder;

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
    background: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEBEEF3),
    border: Color(0xFFE1E5EC),
    cardBorder: Color(0x00000000),
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
    // 순흑에 가까우면 흰 글자와의 대비가 17:1 까지 올라가 글자 둘레가 번져
    // 보인다(할레이션). 바탕을 한 단계 올려 14:1 로 낮춘다. AAA 기준(7:1)에는
    // 여전히 여유가 있다.
    background: Color(0xFF15181E),
    surface: Color(0xFF1E222B),
    surfaceAlt: Color(0xFF2A2F3A),
    border: Color(0xFF333845),
    cardBorder: Color(0xFF333A47),
    textPrimary: Color(0xFFE6E9EF),
    textSecondary: Color(0xFF9BA3B4),
    textTertiary: Color(0xFF6B7385),
    primary: brandBlueDark,
    // 파란 버튼 위에 얹는 글자. 새 바탕색과 맞춰 둔다.
    primaryForeground: Color(0xFF15181E),
    danger: Color(0xFFF87171),
    hot: Color(0xFFFF6B5E),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? cardBorder,
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
      cardBorder: cardBorder ?? this.cardBorder,
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
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
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
