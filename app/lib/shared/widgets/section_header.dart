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
  });

  final String title;

  /// 오른쪽 끝 링크의 글자. [onAction] 과 함께 있어야 나타난다.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = actionLabel;
    final onAction = this.onAction;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.texts.headlineMedium)),
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
  }
}
