import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/community/presentation/widgets/post_card.dart';
import 'package:mogacko/features/event/presentation/widgets/event_card.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/meetup/presentation/widgets/meetup_list_card.dart';
import 'package:mogacko/features/profile/presentation/my_activity_screen.dart';
import 'package:mogacko/features/profile/presentation/profile_provider.dart';
import 'package:mogacko/features/profile/presentation/profile_screen.dart';
import 'package:mogacko/shared/widgets/empty_state.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('내 활동', () {
    testWidgets('숫자를 누르면 그 목록이 열린다', (tester) async {
      await tester.pumpScreen(const ProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('참여 중인 모각코'));
      await tester.pumpAndSettle();

      expect(find.byType(MyActivityScreen), findsOneWidget);
      expect(find.byType(MeetupListCard), findsWidgets);
    });

    testWidgets('누른 것이 골라진 채로 열린다', (tester) async {
      await tester.pumpScreen(const ProfileScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('작성한 글'));
      await tester.pumpAndSettle();

      expect(find.byType(PostCard), findsWidgets);
      expect(find.byType(MeetupListCard), findsNothing);
    });

    testWidgets('셋을 한 화면에서 갈아 끼운다', (tester) async {
      await tester.pumpScreen(
        const MyActivityScreen(kind: MyActivityKind.meetups),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MeetupListCard), findsWidgets);

      // 화면을 셋으로 나누면 모각코를 보다 행사를 보려고 내 정보까지
      // 되돌아가야 한다.
      await tester.tap(find.text('신청한 행사'));
      await tester.pumpAndSettle();

      expect(find.byType(EventCard), findsWidgets);
      expect(find.byType(MeetupListCard), findsNothing);
    });

    testWidgets('숫자와 목록 길이가 같다', (tester) async {
      final container = await tester.pumpScreen(
        const MyActivityScreen(kind: MyActivityKind.meetups),
      );
      await tester.pumpAndSettle();

      final stats = container.read(profileStatsProvider);
      // 세는 곳과 보여주는 곳이 같은 목록을 쓴다.
      expect(
        find.byType(MeetupListCard),
        findsNWidgets(stats.joinedMeetups),
      );
    });

    testWidgets('한 모임의 여러 날을 신청해도 한 줄이다', (tester) async {
      final container = await tester.pumpScreen(
        const MyActivityScreen(kind: MyActivityKind.meetups),
      );
      await tester.pumpAndSettle();

      final before = container.read(profileStatsProvider).joinedMeetups;
      // busan-3 은 이미 하루 신청돼 있다. 같은 모임의 다른 날을 더 신청한다.
      container
          .read(meetupListProvider.notifier)
          .toggleSession('busan-3', 'busan-3-sat');
      await tester.pumpAndSettle();

      // 날이 아니라 모임을 센다. 숫자가 올라가는데 줄이 안 늘면 틀린 것처럼
      // 보인다.
      expect(container.read(profileStatsProvider).joinedMeetups, before);
      expect(find.byType(MeetupListCard), findsNWidgets(before));
    });

    testWidgets('비었으면 무엇을 하면 채워지는지 알려준다', (tester) async {
      final container = await tester.pumpScreen(
        const MyActivityScreen(kind: MyActivityKind.meetups),
      );
      await tester.pumpAndSettle();

      for (final meetup in container.read(myMeetupsProvider).toList()) {
        for (final session in meetup.sessions.where((s) => s.isJoined)) {
          container
              .read(meetupListProvider.notifier)
              .toggleSession(meetup.id, session.id);
        }
      }
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('참여 중인 모각코가 없어요'), findsOneWidget);
    });

    testWidgets('목록에서 상세로 들어간다', (tester) async {
      final container = await tester.pumpScreen(
        const MyActivityScreen(kind: MyActivityKind.posts),
      );
      await tester.pumpAndSettle();

      final post = container.read(myPostsProvider).first;
      await tester.tap(find.text(post.title));
      await tester.pumpAndSettle();

      expect(find.byType(MyActivityScreen), findsNothing);
      expect(find.text(post.body), findsOneWidget);
    });
  });
}
