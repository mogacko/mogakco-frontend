import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 받아오는 동안 세우는 회색 줄.
///
/// 스피너 하나를 화면 가운데 띄우지 않는다. 그러면 목록이 오는 순간 텅 빈
/// 화면에서 꽉 찬 화면으로 한 번에 튀어서, 눈이 자리를 처음부터 다시 찾는다.
/// 올 것의 모양을 미리 그려 두면 채워질 때 자리가 그대로 남는다.
///
/// 움직이지 않는다. 반짝이는 효과는 화면 절반이 회색일 때 오히려 시끄럽고,
/// 진짜 목록보다 눈에 먼저 든다.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.rows = 4, this.height = 92});

  final int rows;

  /// 한 줄의 높이. 실제 카드와 비슷해야 자리가 안 밀린다.
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              0,
              AppSpacing.screenHorizontal,
              AppSpacing.md,
            ),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
      ],
    );
  }
}
