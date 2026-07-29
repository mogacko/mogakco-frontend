import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_bottom_nav.dart';

/// 지금 보고 있는 탭.
///
/// 탭 바만 이 값을 바꾸는 게 아니다. 홈의 '더보기'처럼 다른 화면에서 탭을
/// 건너가는 자리가 있어서, 셸이 상태를 쥐고 있으면 그때마다 콜백을 화면
/// 깊숙이 내려보내야 한다. 그래서 셸 밖에 둔다.
class CurrentTab extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  void select(AppTab tab) => state = tab;
}

final currentTabProvider = NotifierProvider<CurrentTab, AppTab>(
  CurrentTab.new,
);
