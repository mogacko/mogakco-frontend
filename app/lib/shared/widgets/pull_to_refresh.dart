import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 당겨서 새로고침.
///
/// 목록 화면이면 어디서나 같은 자리에서 같은 모양으로 돌게 [RefreshIndicator]
/// 설정을 한곳에 모은다.
///
/// 안쪽 스크롤은 반드시 [AlwaysScrollableScrollPhysics] 여야 한다. 내용이
/// 화면보다 짧으면 스크롤이 잠겨 당길 수조차 없는데, 정작 당기고 싶은 때가
/// 목록이 비었을 때다.
class PullToRefresh extends StatelessWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colors.primary,
      backgroundColor: colors.surface,
      // 기본값은 머티리얼 앱바 높이를 가정해 꽤 아래에서 뜬다. 여기 화면들은
      // 앱바가 없어 그대로 두면 첫 항목을 덮는다.
      edgeOffset: 0,
      child: child,
    );
  }
}

/// 내용이 짧아도 당길 수 있는 스크롤 물리.
///
/// [PullToRefresh] 안에 놓는 스크롤 위젯에 그대로 넘긴다.
const alwaysScrollable = AlwaysScrollableScrollPhysics();
