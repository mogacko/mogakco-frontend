import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/meetup/presentation/meetup_detail_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/meetup/presentation/widgets/participant_roster.dart';
import 'package:mogacko/features/member/presentation/member_provider.dart';
import 'package:mogacko/features/member/presentation/member_screen.dart';
import 'package:mogacko/features/profile/presentation/profile_provider.dart';
import 'package:mogacko/shared/widgets/avatar_stack.dart';
import 'package:mogacko/shared/widgets/empty_state.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('아바타 줄', () {
    Future<void> pumpStack(WidgetTester tester, List<String> names) async {
      await tester.pumpScreen(
        Scaffold(body: Center(child: AvatarStack(names: names))),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('셋까지는 그대로 선다', (tester) async {
      await pumpStack(tester, ['가람', '나윤', '다인']);

      expect(find.textContaining('+'), findsNothing);
      expect(find.text('가'), findsOneWidget);
      expect(find.text('다'), findsOneWidget);
    });

    testWidgets('넷부터는 마지막 칸이 +n 이 된다', (tester) async {
      await pumpStack(tester, ['가람', '나윤', '다인', '라온']);

      // 넷을 넘기면 얼굴이 작아져 누구인지도 못 알아본다. 셋만 세우고 접는다.
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('라'), findsNothing);
    });

    testWidgets('아무도 없으면 자리를 차지하지 않는다', (tester) async {
      await pumpStack(tester, const []);

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.textContaining('+'), findsNothing);
    });
  });

  group('참여자', () {
    testWidgets('신청하면 참여자 목록에 내가 들어간다', (tester) async {
      final container = await tester.pumpScreen(
        const MeetupDetailScreen(meetupId: 'busan-1'),
      );
      await tester.pumpAndSettle();

      final me = container.read(myIdProvider);
      Iterable<String> namesOf() => container
          .read(meetupListProvider)
          .firstWhere((meetup) => meetup.id == 'busan-1')
          .sessions
          .first
          .participants;

      expect(namesOf(), isNot(contains(me)));

      container
          .read(meetupListProvider.notifier)
          .toggleSession('busan-1', 'busan-1-today');

      // 숫자만 올리면 아바타 줄에는 내가 없는데 '참여 중'이라 적힌다.
      expect(namesOf(), contains(me));
    });

    testWidgets('취소하면 목록에서 빠진다', (tester) async {
      final container = await tester.pumpScreen(
        const MeetupDetailScreen(meetupId: 'busan-3'),
      );
      await tester.pumpAndSettle();

      final me = container.read(myIdProvider);
      Iterable<String> namesOf() => container
          .read(meetupListProvider)
          .firstWhere((meetup) => meetup.id == 'busan-3')
          .sessions
          .first
          .participants;

      expect(namesOf(), contains(me));

      container
          .read(meetupListProvider.notifier)
          .toggleSession('busan-3', 'busan-3-fri');

      expect(namesOf(), isNot(contains(me)));
    });

    testWidgets('참여자를 누르면 그 사람 프로필로 간다', (tester) async {
      await tester.pumpScreen(const MeetupDetailScreen(meetupId: 'busan-1'));
      await tester.pumpAndSettle();

      // 참여자 줄은 화면 아래라 스크롤로 만들어질 때까지 끌어와야 한다.
      // 슬리버는 보이는 만큼만 짓는다.
      // 댓글에도 같은 이름이 있다. 참여자 줄 안으로 좁힌다.
      final chip = find.descendant(
        of: find.byType(ParticipantRoster),
        matching: find.text('민서'),
      );
      await tester.dragUntilVisible(
        chip,
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(find.byType(MemberScreen), findsOneWidget);
      expect(find.text('부산 · 데이터 · 부산은행'), findsOneWidget);
    });
  });

  group('남의 프로필', () {
    testWidgets('지역·분야·소속을 한 줄로 잇는다', (tester) async {
      await tester.pumpScreen(const MemberScreen(memberId: '재현'));
      await tester.pumpAndSettle();

      expect(find.text('부산 · 백엔드 · 토스'), findsOneWidget);
      expect(find.text('Spring'), findsOneWidget);
    });

    testWidgets('나를 열면 내 프로필이 나온다', (tester) async {
      final container = await tester.pumpScreen(const MemberScreen(memberId: 'x'));
      await tester.pumpAndSettle();

      final me = container.read(profileProvider);
      // 목업이 아니라 내 프로필을 줘야 프로필 수정에서 고친 게 여기에도 보인다.
      expect(container.read(memberProvider(me.id))?.nickname, me.nickname);
    });

    testWidgets('없는 사람은 없다고 말한다', (tester) async {
      await tester.pumpScreen(const MemberScreen(memberId: '없는사람'));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('찾을 수 없는 사람이에요'), findsOneWidget);
    });

    testWidgets('운영진은 지역·분야 대신 자리를 적는다', (tester) async {
      await tester.pumpScreen(const MemberScreen(memberId: '운영진'));
      await tester.pumpAndSettle();

      // 사람이 아니라 자리라, 소속을 적으면 어느 지부 담당인지 오해가 생긴다.
      expect(find.text('지부 운영진'), findsOneWidget);
    });
  });
}
