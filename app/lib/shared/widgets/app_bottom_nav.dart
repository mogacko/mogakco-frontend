import 'dart:ui';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 하단 탭 정의.
///
/// 아이콘은 SF Symbols를 옮겨온 [CupertinoIcons]를 쓴다. Material 아이콘은
/// 획이 두껍고 형태가 달라 iOS 탭 바처럼 보이지 않는다.
enum AppTab {
  home('홈', CupertinoIcons.house, CupertinoIcons.house_fill),
  community(
    '커뮤니티',
    CupertinoIcons.bubble_left_bubble_right,
    CupertinoIcons.bubble_left_bubble_right_fill,
  ),
  meetup('모각코', CupertinoIcons.person_2, CupertinoIcons.person_2_fill),
  event('행사', CupertinoIcons.ticket, CupertinoIcons.ticket_fill),
  profile(
    '내 정보',
    CupertinoIcons.person_crop_circle,
    CupertinoIcons.person_crop_circle_fill,
  );

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

  /// 탭 바 높이.
  ///
  /// HIG 기준값 49pt에 맞춘다. 여기에 기기가 요구하는 안전영역이 더해지므로
  /// (홈 인디케이터가 있는 기기는 34pt 안팎) 바 자체는 넉넉히 잡지 않는다.
  static const barHeight = 48.0;

  /// 안전영역이 0으로 잡히는 환경에서 쓰는 여백.
  ///
  /// 홈 화면에 추가한 PWA 는 안전영역을 넘겨주지 않아 이 값이 그대로 바닥
  /// 여백이 된다. 너무 줄이면 탭이 화면 끝에 붙어 답답해 보인다.
  static const _minBottomPadding = 16.0;

  /// 안전영역을 그대로 쓰면 바가 지나치게 두꺼워 보인다.
  ///
  /// 홈 인디케이터를 가리지 않을 만큼만 남기고 나머지는 덜어낸다.
  /// 인디케이터 자체는 8pt 남짓이라 이 정도면 겹치지 않는다.
  static const _maxBottomPadding = 20.0;

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  /// 이 기기에서 탭 바가 실제로 차지하는 높이.
  ///
  /// 탭 바가 반투명이라 본문이 그 아래로 지나간다(`extendBody`). 스크롤하는
  /// 화면은 마지막 항목이 바 뒤에 깔려 잘리므로, 목록 끝에 이만큼을 비워
  /// 둬야 한다. 화면마다 숫자를 따로 적으면 바 높이를 고칠 때 어긋난다.
  static double contentInset(BuildContext context) =>
      barHeight + _safeBottom(context);

  /// 안전영역을 이 컴포넌트가 쓰는 범위로 좁힌 값
  static double _safeBottom(BuildContext context) => MediaQuery.of(
    context,
  ).padding.bottom.clamp(_minBottomPadding, _maxBottomPadding);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = _safeBottom(context);

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
            Icon(selected ? tab.activeIcon : tab.icon, size: 24, color: color),
            const SizedBox(height: 2),
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
