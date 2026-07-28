import 'package:flutter/material.dart';

/// 타이포그래피 토큰.
///
/// 색은 담지 않는다. 색은 ThemeData 조립 단계에서 테마별로 주입한다.
abstract final class AppTypography {
  static const fontFamily = 'Pretendard';

  /// 한글은 라틴 대비 시각 높이가 커서 기본 행간이 좁게 보인다.
  /// 본문 1.5, 제목 1.3 정도가 읽기 편하다.
  static const _bodyHeight = 1.5;
  static const _headingHeight = 1.3;

  static const displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: _headingHeight,
    letterSpacing: -0.6,
  );

  static const headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: _headingHeight,
    letterSpacing: -0.4,
  );

  static const headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: _headingHeight,
    letterSpacing: -0.3,
  );

  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
  );

  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: _bodyHeight,
    letterSpacing: -0.1,
  );

  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: _bodyHeight,
    letterSpacing: -0.1,
  );

  /// 버튼 라벨
  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
  );

  static const labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: -0.1,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}
