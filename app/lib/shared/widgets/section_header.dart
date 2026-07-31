import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 구획 제목.
///
/// 카드 하나가 아니라 그 묶음이 무엇인지 말한다. 화면 여백에 맞춰 세워야
/// 다음 구획이 아래로 이어질 때 같은 줄에서 시작한다.
///
/// 제목 앞에 아이콘을 붙이지 않는다. 제목이 이미 무엇인지 말하고 있어
/// 앞에 그림을 하나 더 두면 장식만 는다.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.divided = false,
  });

  final String title;

  /// 오른쪽 끝 링크의 글자. [onAction] 과 함께 있어야 나타난다.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 제목 위에 얇은 선을 긋는다.
  ///
  /// 여백만으로 끊으면 스크롤 중에 어디서 구획이 갈리는지 모호하다. 다만
  /// 상자를 두르지는 않는다 — 선은 구조를 표시하는 데까지만 쓰고, 화면 끝까지
  /// 긋지 않고 본문 여백에 맞춰 들여 쓴다.
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = actionLabel;
    final onAction = this.onAction;

    final header = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Row(
        children: [
          // 구획 이름은 내용보다 작다. 같은 크기면 무엇이 본문인지 흐려진다.
          Expanded(child: Text(title, style: context.texts.titleLarge)),
          if (label != null && onAction != null)
            // 제목과 같은 줄이라 버튼처럼 보일 필요가 없다. 색과 화살표로
            // 누를 수 있다는 것만 알린다.
            Semantics(
              button: true,
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: context.texts.labelMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: AppSize.iconSm - 4,
                        color: colors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!divided) return header;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          indent: AppSpacing.screenHorizontal,
          endIndent: AppSpacing.screenHorizontal,
          color: colors.border,
        ),
        const SizedBox(height: AppSpacing.xl),
        header,
      ],
    );
  }
}
