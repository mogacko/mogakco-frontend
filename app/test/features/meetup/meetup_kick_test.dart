import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/meetup/domain/meetup.dart';
import 'package:mogacko/features/meetup/presentation/meetup_detail_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/meetup/presentation/widgets/participant_roster.dart';
import 'package:mogacko/features/safety/presentation/safety_provider.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('내보내기', () {
    /// busan-3 은 evan(나)이 연 모임이다.
    Meetup meetupOf(ProviderContainer container) => container
        .read(meetupListProvider)
        .firstWhere((meetup) => meetup.id == 'busan-3');

    testWidgets('내보내면 모든 날짜에서 빠진다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // 재현은 busan-3 의 첫 날에만 있다. 여러 날에 걸친 사람을 고른다.
      const who = '재현';
      final before = meetupOf(container);
      expect(
        before.sessions.where((s) => s.participants.contains(who)),
        isNotEmpty,
      );

      container.read(meetupListProvider.notifier).kick('busan-3', who);

      // 이틀 다 오기로 한 사람을 두 번 눌러야 하면, 한 번만 누르고 끝난 줄
      // 알았다가 다음 날 마주친다.
      expect(
        meetupOf(container).sessions.expand((s) => s.participants),
        isNot(contains(who)),
      );
    });

    testWidgets('내보낸 사람은 다시 신청할 수 없다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      container.read(meetupListProvider.notifier).kick('busan-3', '수민');

      expect(meetupOf(container).banned, contains('수민'));
      expect(meetupOf(container).canKick('수민'), isFalse);

      // 내보내기만 하고 끝내면 그 사람이 곧바로 다시 신청한다.
      final retried = meetupOf(container).toggleSession('busan-3-fri', '수민');
      expect(
        retried.sessions.expand((session) => session.participants),
        isNot(contains('수민')),
      );
    });

    testWidgets('모임장 자신은 뺄 수 없다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final meetup = meetupOf(container);
      // 연 사람이 없는 모임은 모임이 아니다. 접으려면 접기가 따로 있다.
      expect(meetup.canKick(meetup.host), isFalse);
    });

    testWidgets('모임장에게만 X 가 붙는다', (tester) async {
      // busan-3 의 모임장은 나다.
      await tester.pumpScreen(const MeetupDetailScreen(meetupId: 'busan-3'));
      await tester.pumpAndSettle();

      final roster = find.byType(ParticipantRoster);
      await tester.dragUntilVisible(
        roster,
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: roster, matching: find.bySemanticsLabel('재현 내보내기')),
        findsOneWidget,
      );
    });

    testWidgets('남의 모임에는 X 가 없다', (tester) async {
      // busan-1 의 모임장은 재현이다.
      await tester.pumpScreen(const MeetupDetailScreen(meetupId: 'busan-1'));
      await tester.pumpAndSettle();

      final roster = find.byType(ParticipantRoster);
      await tester.dragUntilVisible(
        roster,
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: roster, matching: find.bySemanticsLabel('민서 내보내기')),
        findsNothing,
      );
    });

    testWidgets('내보내기와 차단은 따로 정한다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      container.read(meetupListProvider.notifier).kick('busan-3', '서연');

      // 내보내기는 이 모임에서만 빼는 것이다. 앱 전체에서 안 보이게 하는 건
      // 차단이고 그건 따로 고를 일이다.
      expect(container.read(blockedProvider), isNot(contains('서연')));
      expect(meetupOf(container).banned, contains('서연'));
    });
  });
}
