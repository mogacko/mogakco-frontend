import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/event/presentation/event_provider.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/profile/presentation/profile_provider.dart';
import 'package:mogacko/features/profile/presentation/profile_screen.dart';
import 'package:mogacko/features/profile/presentation/settings_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('내 활동 요약', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('숫자를 박아두지 않고 실제 참여 상태에서 센다', () {
      final stats = makeContainer().read(profileStatsProvider);

      // 목업에 미리 신청해 둔 것들.
      expect(stats.joinedSessions, 2);
      expect(stats.appliedEvents, 1);
      // 내 닉네임으로 쓴 글.
      expect(stats.posts, 1);
    });

    test('모임을 신청하면 곧바로 올라간다', () {
      final container = makeContainer();
      final before = container.read(profileStatsProvider).joinedSessions;

      container
          .read(meetupListProvider.notifier)
          .toggleSession('busan-4', 'busan-4-sun');

      expect(container.read(profileStatsProvider).joinedSessions, before + 1);
    });

    test('행사를 취소하면 곧바로 내려간다', () {
      final container = makeContainer();
      final before = container.read(profileStatsProvider).appliedEvents;

      container.read(eventListProvider.notifier).toggleApply('busan-e2');

      expect(container.read(profileStatsProvider).appliedEvents, before - 1);
    });

    test('다른 지역에 신청한 것도 내 기록으로 센다', () {
      // 서울 모임 하나가 미리 신청돼 있다. 부산을 보고 있어도 빠지지 않는다.
      expect(makeContainer().read(profileStatsProvider).joinedSessions, 2);
    });
  });

  group('ProfileScreen', () {
    testWidgets('누구인지를 한 줄로 잇는다', (tester) async {
      await tester.pumpScreen(const ProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('내 정보'), findsOneWidget);
      expect(find.text('evan'), findsOneWidget);
      // 지역·분야·소속을 라벨 없이 이어 붙인다.
      expect(find.text('부산 · 프론트엔드 · 오션스타'), findsOneWidget);
    });

    testWidgets('스택과 관심분야를 나눠 세운다', (tester) async {
      await tester.pumpScreen(const ProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('스택'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('관심분야'), findsOneWidget);
    });

    testWidgets('선택 약관은 설정에서 끄고 켤 수 있다', (tester) async {
      await tester.pumpScreen(const SettingsScreen());
      await tester.pumpAndSettle();

      // 목록이 캐시 영역까지 미리 만들어 두므로 찾기만 해서는 화면 밖에 있다.
      // 눌러야 하니 실제로 끌어와야 한다.
      final toggle = find.byType(Switch);
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(toggle).value, isFalse);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('로그아웃은 바로 나가지 않고 확인을 먼저 받는다', (tester) async {
      await tester.pumpScreen(const SettingsScreen());
      await tester.pumpAndSettle();

      final logout = find.text('로그아웃');
      await tester.ensureVisible(logout);
      await tester.pumpAndSettle();
      await tester.tap(logout);
      await tester.pumpAndSettle();

      expect(find.text('로그아웃할까요?'), findsOneWidget);
    });
  });
}
