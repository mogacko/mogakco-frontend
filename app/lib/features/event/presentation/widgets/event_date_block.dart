import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// 달력 한 칸처럼 세우는 날짜.
///
/// 행사는 '무엇을 하느냐'만큼 '언제 하느냐'로 고르게 된다. 날짜가 본문 속 한
/// 줄로 섞여 있으면 목록을 훑으며 비교할 수 없어서 왼쪽에 따로 세운다.
class EventDateBlock extends StatelessWidget {
  const EventDateBlock({super.key, required this.date, this.compact = false});

  final DateTime date;

  /// 홈처럼 좁은 자리에 놓을 때. 폭과 글자를 한 단계 줄이고 면을 깔지 않는다.
  ///
  /// 행사 탭에서는 카드(surfaceAlt) 위에 놓여 밝은 면이 달력 칸처럼 보이지만,
  /// 홈에서는 페이지 배경 위에 바로 놓인다. 같은 면을 깔면 라이트에서는
  /// 흰 바탕에 흰 면이라 보이지 않고 다크에서만 상자가 떠서, 두 테마가
  /// 다르게 보인다. 홈에서는 아예 깔지 않아 양쪽을 맞춘다.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    // 토·일은 달력에서 하듯 색을 달리한다. 주말인지가 갈 수 있는지를 가른다.
    final isWeekend = date.weekday >= 6;

    return Container(
      width: compact ? 44 : 52,
      padding: EdgeInsets.symmetric(
        vertical: compact ? AppSpacing.xs + 2 : AppSpacing.sm,
      ),
      decoration: compact
          ? null
          : BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${date.month}월',
            style: context.texts.labelSmall?.copyWith(
              color: colors.textTertiary,
              height: 1.1,
            ),
          ),
          Text(
            '${date.day}',
            style: compact
                ? context.texts.titleLarge?.copyWith(height: 1.2)
                : context.texts.headlineMedium?.copyWith(height: 1.2),
          ),
          Text(
            weekdays[date.weekday - 1],
            style: context.texts.labelSmall?.copyWith(
              color: isWeekend ? colors.primary : colors.textTertiary,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
