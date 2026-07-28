import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 하단 탭 정의.
enum AppTab {
  home('홈', Icons.home_outlined, Icons.home),
  community('커뮤니티', Icons.forum_outlined, Icons.forum),
  meetup('모임', Icons.groups_outlined, Icons.groups),
  profile('내 정보', Icons.person_outline, Icons.person);

  const AppTab(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;

  /// 선택됐을 때 쓰는 채워진 아이콘
  final IconData activeIcon;
}

/// 하단 탭 바.
///
/// Apple HIG의 탭 바 규격을 따른다.
/// - 높이 49pt에 하단 안전영역을 더한다
/// - 선택 표시는 별도 인디케이터 없이 색으로만 나타낸다
/// - 라벨은 아이콘 아래 작은 글씨로 항상 보인다
/// - 배경은 반투명으로 두고 위쪽에 머리카락 굵기 구분선을 둔다
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  /// HIG가 규정한 탭 바 높이
  static const barHeight = 49.0;

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        // 아래 내용이 비쳐 보이는 iOS 탭 바 특유의 재질감.
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background.withValues(alpha: 0.82),
            border: Border(top: BorderSide(color: colors.border, width: 0.5)),
          ),
          child: SizedBox(
            height: barHeight + bottomInset,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Row(
                children: [
                  for (final tab in AppTab.values)
                    Expanded(
                      child: _TabItem(
                        tab: tab,
                        selected: tab == current,
                        onTap: () => onSelect(tab),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        // HIG의 탭은 물결 효과 없이 즉각 색만 바뀐다.
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? tab.activeIcon : tab.icon, size: 25, color: color),
            const SizedBox(height: AppSpacing.xs - 2),
            Text(
              tab.label,
              style: TextStyle(
                // HIG 탭 라벨은 10pt 수준으로 작게 둔다.
                fontFamily: 'Pretendard',
                fontSize: 10,
                height: 1.1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
