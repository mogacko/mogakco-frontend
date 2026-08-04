import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/meetup/domain/meetup.dart';
import 'package:mogacko/features/meetup/presentation/meetup_detail_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/meetup/presentation/widgets/cancelled_notice.dart';
import 'package:mogacko/shared/providers/now_provider.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('모각코 접기', () {
    Cancellation reason(WidgetTester tester, DateTime now) =>
        Cancellation(reason: CancelReason.tooFew, at: now);

    testWidgets('접힌 모임은 목록에 남고 사유가 보인다', (tester) async {
      final container = await tester.pumpScreen(
        const MeetupDetailScreen(meetupId: 'busan-4'),
      );
      await tester.pumpAndSettle();

      // 오기로 했던 사람은 그 자리가 어떻게 됐는지 확인하러 온다. 통째로
      // 사라지면 자기가 잘못 본 건지 알 수 없다.
      expect(
        container.read(visibleMeetupsProvider).map((m) => m.id),
        contains('busan-4'),
      );
      expect(find.byType(CancelledNotice), findsOneWidget);
      expect(find.text('장소 문제'), findsOneWidget);
    });

    testWidgets('접힌 모임은 홈에 세우지 않는다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // 홈 맨 위는 '오늘 갈 곳'을 묻는 자리다. 안 열리는 자리가 답이 될 수 없다.
      expect(
        container.read(heroMeetupsProvider).map((entry) => entry.meetup.id),
        isNot(contains('busan-4')),
      );
    });

    testWidgets('접힌 모임에는 신청할 수 없다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final before = container
          .read(meetupListProvider)
          .firstWhere((m) => m.id == 'busan-4');

      container
          .read(meetupListProvider.notifier)
          .toggleSession('busan-4', before.sessions.first.id);

      final after = container
          .read(meetupListProvider)
          .firstWhere((m) => m.id == 'busan-4');
      expect(after.sessions.first.participants, before.sessions.first.participants);
      expect(after.sessions.first.isJoined, isFalse);
    });

    testWidgets('날짜 줄이 취소로 잠긴다', (tester) async {
      await tester.pumpScreen(const MeetupDetailScreen(meetupId: 'busan-4'));
      await tester.pumpAndSettle();

      // 일정 줄은 지도 아래라 스크롤로 지어질 때까지 끌어와야 한다.
      final pill = find.text('취소');
      await tester.dragUntilVisible(
        pill,
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(pill, findsWidgets);
      // 접힌 자리에 '참여 중'이나 '신청'이 남아 있으면 안 된다.
      expect(find.text('신청'), findsNothing);
      expect(find.text('참여 중'), findsNothing);
    });

    testWidgets('사유를 달아 접으면 그대로 남는다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final now = container.read(nowProvider);
      container
          .read(meetupListProvider.notifier)
          .cancel('busan-1', reason(tester, now));

      final meetup = container
          .read(meetupListProvider)
          .firstWhere((m) => m.id == 'busan-1');
      expect(meetup.isCancelled, isTrue);
      expect(meetup.cancellation!.reason, CancelReason.tooFew);
      expect(meetup.cancellation!.label, '인원 부족');
    });

    testWidgets('직접 적은 사유가 있으면 그것을 보여준다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      container
          .read(meetupListProvider.notifier)
          .cancel(
            'busan-1',
            Cancellation(
              reason: CancelReason.other,
              note: '카페에 단체석이 없어졌어요',
              at: container.read(nowProvider),
            ),
          );

      final meetup = container
          .read(meetupListProvider)
          .firstWhere((m) => m.id == 'busan-1');
      // '기타'만 적혀 있으면 왜 안 열리는지 물어볼 데를 또 찾아야 한다.
      expect(meetup.cancellation!.label, '카페에 단체석이 없어졌어요');
    });

    testWidgets('기타는 직접 적어야 고른 것으로 친다', (tester) async {
      expect(CancelReason.other.needsNote, isTrue);
      expect(CancelReason.weather.needsNote, isFalse);
    });
  });
}
