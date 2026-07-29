import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/shared/widgets/app_bottom_nav.dart';

import '../helpers/pump_app.dart';

void main() {
  group('AppBottomNav', () {
    testWidgets('다섯 탭을 정해진 순서로 보여준다', (tester) async {
      await tester.pumpScreen(
        Scaffold(
          bottomNavigationBar: AppBottomNav(
            current: AppTab.home,
            onSelect: (_) {},
          ),
        ),
      );

      expect(AppTab.values.map((t) => t.label), [
        '홈',
        '커뮤니티',
        '모각코',
        '행사',
        '내 정보',
      ]);
      for (final tab in AppTab.values) {
        expect(find.text(tab.label), findsOneWidget);
      }
    });

    testWidgets('선택된 탭만 채워진 아이콘을 쓴다', (tester) async {
      await tester.pumpScreen(
        Scaffold(
          bottomNavigationBar: AppBottomNav(
            current: AppTab.event,
            onSelect: (_) {},
          ),
        ),
      );

      expect(find.byIcon(AppTab.event.activeIcon), findsOneWidget);
      expect(find.byIcon(AppTab.event.icon), findsNothing);
      expect(find.byIcon(AppTab.home.icon), findsOneWidget);
    });

    testWidgets('탭을 누르면 어떤 탭인지 알려준다', (tester) async {
      AppTab? tapped;
      await tester.pumpScreen(
        Scaffold(
          bottomNavigationBar: AppBottomNav(
            current: AppTab.home,
            onSelect: (tab) => tapped = tab,
          ),
        ),
      );

      await tester.tap(find.text('행사'));
      await tester.pumpAndSettle();

      expect(tapped, AppTab.event);
    });
  });
}
