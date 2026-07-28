import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../home/presentation/home_screen.dart';
import 'placeholder_tab.dart';

/// 로그인 이후의 뼈대 화면.
///
/// 탭을 오갈 때 각 화면의 스크롤 위치와 상태가 남도록 [IndexedStack]으로 붙여둔다.
/// 탭마다 별도 URL이 필요해지면 go_router의 StatefulShellRoute로 옮기면 된다.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _current = AppTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      // 탭 바가 반투명이라 본문이 그 아래로 비쳐 보이게 한다.
      extendBody: true,
      body: IndexedStack(
        index: AppTab.values.indexOf(_current),
        children: const [
          HomeScreen(),
          PlaceholderTab(tab: AppTab.community),
          PlaceholderTab(tab: AppTab.meetup),
          PlaceholderTab(tab: AppTab.event),
          PlaceholderTab(tab: AppTab.profile),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        current: _current,
        onSelect: (tab) => setState(() => _current = tab),
      ),
    );
  }
}
