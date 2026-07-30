import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// 매주 열리는 모임이라는 표시.
///
/// 이번 주만 열리는 자리와 구분된다. 꾸준히 나갈 곳을 찾는 사람에게는
/// 이게 장소보다 먼저 걸린다.
class RecurringBadge extends StatelessWidget {
  const RecurringBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.repeat, size: 11, color: colors.primary),
          const SizedBox(width: 3),
          Text(
            '정기',
            style: context.texts.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
