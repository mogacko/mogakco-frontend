/// 간격 토큰. 4의 배수로 통일해 화면 간 리듬을 맞춘다.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;

  /// 화면 좌우 기본 여백
  static const screenHorizontal = 24.0;
}

/// 모서리 반경 토큰.
abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;

  /// pill 형태 버튼·칩
  static const full = 999.0;
}

/// 컴포넌트 고정 치수.
abstract final class AppSize {
  /// 주요 버튼 높이. 소셜 버튼과 동일하게 맞춰 정렬을 유지한다.
  static const buttonHeight = 54.0;
  static const inputHeight = 54.0;
  static const iconSm = 18.0;
  static const iconMd = 22.0;
}
