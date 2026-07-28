import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// 가입 진행 단계 표시줄.
///
/// 몇 단계가 남았는지 보이면 중도 이탈이 줄어든다. 총 단계 수가 늘면
/// [totalSteps]만 조정한다.
class SignupProgress extends StatelessWidget {
  const SignupProgress({super.key, required this.step, this.totalSteps = 3});

  /// 1부터 시작하는 현재 단계
  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 1; i <= totalSteps; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step ? colors.primary : colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              if (i != totalSteps) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('$step / $totalSteps', style: context.texts.labelSmall),
      ],
    );
  }
}
