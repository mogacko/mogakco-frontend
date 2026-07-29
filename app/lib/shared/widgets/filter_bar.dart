import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 목록 위에 놓는 가로 필터.
///
/// 세그먼트 컨트롤은 항목이 넷을 넘으면 글자가 뭉개진다. 분류는 늘어나기
/// 마련이라 옆으로 밀어 보는 알약 줄로 둔다.
///
/// 고른 것과 안 고른 것은 테두리가 아니라 면으로 가른다. 목록 위에 테두리가
/// 여러 줄 겹치면 정작 아래 내용보다 시끄러워진다.
class FilterBar<T> extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
    this.countOf,
  });

  final List<T> options;
  final T selected;

  final String Function(T option) labelOf;
  final ValueChanged<T> onSelect;

  /// 항목별 개수. 넘기면 라벨 뒤에 붙는다.
  ///
  /// 0인 분류를 눌러 빈 화면을 보게 되는 일을 미리 막아준다.
  final int Function(T option)? countOf;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // 가로 스크롤이라 높이를 고정해야 한다. 알약은 이 높이를 그대로 채우므로
      // 이 값이 곧 손가락이 닿는 높이다. 40이면 한 줄짜리 알약치고 넉넉하다.
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final option = options[index];
          return _FilterPill(
            label: labelOf(option),
            count: countOf?.call(option),
            selected: option == selected,
            onTap: () => onSelect(option),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = this.count;

    final background = selected ? colors.primary : colors.surfaceAlt;
    final foreground = selected ? colors.primaryForeground : colors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: context.texts.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      '$count',
                      style: context.texts.labelSmall?.copyWith(
                        // 개수는 분류명에 딸린 값이라 한 단계 물러나 있어야
                        // 무엇을 고르는 자리인지가 먼저 읽힌다.
                        color: selected
                            ? colors.primaryForeground.withValues(alpha: 0.7)
                            : colors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
