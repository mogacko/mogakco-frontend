import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../community/presentation/community_screen.dart';
import '../../event/presentation/event_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../meetup/presentation/meetup_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'tab_provider.dart';

/// 로그인 이후의 뼈대 화면.
///
/// 탭을 오갈 때 각 화면의 스크롤 위치와 상태가 남도록 [IndexedStack]으로 붙여둔다.
/// 탭마다 별도 URL이 필요해지면 go_router의 StatefulShellRoute로 옮기면 된다.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentTabProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      // 탭 바가 반투명이라 본문이 그 아래로 비쳐 보이게 한다.
      extendBody: true,
      body: IndexedStack(
        index: AppTab.values.indexOf(current),
        // 순서는 AppTab 선언 순서와 같아야 한다.
        children: const [
          HomeScreen(),
          CommunityScreen(),
          MeetupScreen(),
          EventScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        current: current,
        onSelect: (tab) => ref.read(currentTabProvider.notifier).select(tab),
      ),
    );
  }
}
