import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bottom_nav.dart';

/// 아직 만들지 않은 탭.
///
/// 탭 바 동작을 먼저 확인할 수 있도록 자리만 잡아둔다.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 40, color: colors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(tab.label, style: context.texts.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '다음 스프린트에 만들어요',
              style: context.texts.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
