import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 읽기만 하는 태그.
///
/// 프로필의 스택·관심분야처럼 이미 정해진 값을 늘어놓을 때 쓴다. 누를 수
/// 없으니 테두리를 두르지 않고 면으로만 구분한다. 열 개 넘게 붙는 자리라
/// 테두리가 들어가면 글자보다 선이 먼저 보인다.
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, this.tone = TagTone.neutral});

  final String label;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (background, foreground) = switch (tone) {
      TagTone.neutral => (colors.surface, colors.textSecondary),
      // 브랜드 색을 옅게 깔고 글자만 진하게 둔다. 채운 알약은 버튼처럼
      // 보여서, 누를 수 없는 태그에는 쓰지 않는다.
      TagTone.brand => (
        colors.primary.withValues(alpha: 0.10),
        colors.primary,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm - 2,
      ),
      child: Text(
        label,
        style: context.texts.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

enum TagTone { neutral, brand }
