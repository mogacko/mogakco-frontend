import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

/// 한 걸음 뒤로.
///
/// 돌아갈 데가 없으면 홈으로 보낸다. 웹에서는 상세 주소로 바로 들어올 수
/// 있어서 — 링크를 받아 열거나 새로고침하면 — 뒤로 갈 화면이 아예 없는 상태가
/// 된다. 그때 [Navigator.maybePop] 은 조용히 아무 일도 하지 않아, 뒤로가기
/// 버튼이 고장 난 것처럼 보인다.
void goBack(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  router.go(AppRoute.home);
}
