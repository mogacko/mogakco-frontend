import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'brand_icons.dart';

enum SocialProvider { kakao, google, apple }

/// 제공자별 브랜드 스펙.
///
/// 배경·전경색은 각 사의 가이드라인이 정한 값이라 앱 테마를 따르지 않는다.
/// 구글과 애플은 다크 모드 변형을 별도로 규정하고 있어 밝기에 따라 갈린다.
class _BrandStyle {
  const _BrandStyle({
    required this.background,
    required this.foreground,
    required this.label,
    this.border,
  });

  final Color background;
  final Color foreground;
  final String label;
  final Color? border;
}

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
  });

  final SocialProvider provider;
  final VoidCallback? onPressed;

  /// 좌측 아이콘(여백 16 + 아이콘 20)이 차지하는 폭. 라벨을 이만큼 물러나게 한다.
  static const _labelInset = AppSpacing.lg + AppSize.iconMd + AppSpacing.sm;

  _BrandStyle _styleFor(bool isDark) {
    switch (provider) {
      case SocialProvider.kakao:
        return const _BrandStyle(
          background: BrandColors.kakaoBackground,
          foreground: BrandColors.kakaoForeground,
          label: '카카오로 시작하기',
        );
      case SocialProvider.google:
        return _BrandStyle(
          background: isDark
              ? BrandColors.googleDarkBackground
              : BrandColors.googleLightBackground,
          foreground: isDark
              ? BrandColors.googleDarkForeground
              : BrandColors.googleLightForeground,
          border: isDark
              ? BrandColors.googleDarkBorder
              : BrandColors.googleLightBorder,
          label: 'Google로 시작하기',
        );
      case SocialProvider.apple:
        return _BrandStyle(
          background: isDark
              ? BrandColors.appleDarkBackground
              : BrandColors.appleLightBackground,
          foreground: isDark
              ? BrandColors.appleDarkForeground
              : BrandColors.appleLightForeground,
          label: 'Apple로 시작하기',
        );
    }
  }

  Widget _icon(Color foreground) {
    switch (provider) {
      case SocialProvider.kakao:
        return BrandIcons.kakao(color: foreground);
      case SocialProvider.google:
        return BrandIcons.google();
      case SocialProvider.apple:
        return BrandIcons.apple(color: foreground);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = _styleFor(isDark);

    return SizedBox(
      height: AppSize.buttonHeight,
      child: Material(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: style.border != null
                  ? Border.all(color: style.border!)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 아이콘은 왼쪽에 고정하고 라벨은 버튼 정중앙에 둔다.
                // 라벨 길이가 달라도 세 버튼의 글자 위치가 흔들리지 않는다.
                Positioned(left: AppSpacing.lg, child: _icon(style.foreground)),
                Padding(
                  // 버튼이 좁아져도 라벨이 아이콘 위로 올라타지 않도록
                  // 아이콘이 차지하는 폭만큼 양쪽을 비워둔다.
                  padding: const EdgeInsets.symmetric(horizontal: _labelInset),
                  child: Text(
                    style.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      color: style.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
