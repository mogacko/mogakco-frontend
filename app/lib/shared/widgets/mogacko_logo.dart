import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../domain/chapter.dart';

/// 브랜드 로고.
///
/// 원본 SVG가 획 색을 `currentColor`로 두고 있어 [SvgTheme.currentColor]로
/// 색을 주입한다. `colorFilter`로 덮지 않는 이유는 그 경우 투명 영역까지
/// 칠해질 수 있어서다.
///
/// 색을 지정하지 않으면 밝기에 따라 자동으로 고른다.
/// 라이트는 브랜드 블루, 다크는 흰색이다.
class MogackoLogo extends StatelessWidget {
  /// 정사각 심볼. 스플래시·아이콘처럼 정중앙에 놓을 때 쓴다.
  const MogackoLogo.square({super.key, required this.size, this.color})
    : _asset = 'assets/logos/mogakco-logo-square.svg',
      _aspectRatio = 1,
      chapter = null;

  /// 가로형 워드마크. 화면 상단 헤더용.
  const MogackoLogo.horizontal({super.key, required this.size, this.color})
    : _asset = 'assets/logos/mogakco-logo.svg',
      _aspectRatio = 214 / 72,
      chapter = null;

  /// 지역 챕터 워드마크.
  // 에셋 경로를 [Chapter]에서 꺼내 오므로 컴파일 타임 상수가 될 수 없다.
  // ignore: prefer_const_constructors_in_immutables
  MogackoLogo.chapter({
    super.key,
    required Chapter this.chapter,
    required this.size,
    this.color,
  }) : _asset = chapter.logoAsset,
       _aspectRatio = 304 / 72;

  final String _asset;

  /// 챕터 워드마크일 때 그 지역. 다른 형태에서는 null이다.
  final Chapter? chapter;

  /// 원본 SVG의 가로/세로 비율. [size]를 높이로 두고 폭을 계산한다.
  final double _aspectRatio;

  /// 로고 높이
  final double size;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolved =
        color ?? (isDark ? const Color(0xFFFFFFFF) : AppColors.brandBlue);

    return SvgPicture.asset(
      _asset,
      height: size,
      width: size * _aspectRatio,
      theme: SvgTheme(currentColor: resolved),
      // 로고는 화면 낭독 시 서비스명으로 읽히면 충분하다.
      // 챕터 워드마크는 지역까지 읽혀야 한다. 전부 '모각코'로만 읽히면
      // 화면 낭독으로는 서울과 부산을 구분할 수 없다.
      semanticsLabel: chapter == null ? '모각코' : '모각코 ${chapter!.label}',
    );
  }
}
