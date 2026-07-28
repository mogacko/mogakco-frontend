import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// 화면 높이를 채우되 넘치면 스크롤되는 본문 레이아웃.
///
/// 가입 흐름의 화면들은 위쪽에 안내문, 아래쪽에 액션 버튼을 두고 그 사이를
/// [Spacer]로 벌린다. 이 배치는 화면이 짧아지는 순간 그대로 오버플로하므로
/// 최소 높이를 화면만큼 보장한 채 스크롤을 허용한다.
///
/// [child]로는 [Spacer]를 쓰는 [Column]을 그대로 넘기면 된다.
class FullHeightScrollView extends StatelessWidget {
  const FullHeightScrollView({
    super.key,
    required this.child,
    this.horizontalPadding = AppSpacing.screenHorizontal,
  });

  final Widget child;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            // Spacer가 남은 공간을 먹으려면 Column의 높이가 확정돼야 한다.
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}
