import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/community/presentation/community_screen.dart';
import 'package:mogacko/features/community/presentation/post_provider.dart';
import 'package:mogacko/features/community/presentation/widgets/post_card.dart';
import 'package:mogacko/features/event/presentation/event_provider.dart';
import 'package:mogacko/features/event/presentation/event_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/meetup/presentation/meetup_screen.dart';
import 'package:mogacko/shared/data/mock_delay.dart';
import 'package:mogacko/shared/data/mock_failure.dart';
import 'package:mogacko/shared/widgets/empty_state.dart';
import 'package:mogacko/shared/widgets/list_skeleton.dart';
import 'package:mogacko/shared/widgets/load_failure.dart';

import '../helpers/pump_app.dart';

extension on WidgetTester {
  /// 목업 왕복은 진짜 타이머라 pump 로 시계를 돌려야 끝난다.
  /// 그냥 await 하면 프레임이 안 흘러 영원히 안 돌아온다.
  Future<void> reload(Future<void> running) async {
    await pump(mockNetworkDelay);
    await running;
    await pumpAndSettle();
  }
}

void main() {
  group('첫 로딩', () {
    testWidgets('받는 동안 올 것의 모양을 미리 그린다', (tester) async {
      await tester.pumpScreen(const CommunityScreen(), settle: false);
      // 아직 안 왔다.
      await tester.pump();

      expect(find.byType(ListSkeleton), findsOneWidget);
      expect(find.byType(PostCard), findsNothing);

      await tester.pump(mockNetworkDelay);
      await tester.pumpAndSettle();

      // 오고 나면 스켈레톤은 사라진다.
      expect(find.byType(ListSkeleton), findsNothing);
      expect(find.byType(PostCard), findsWidgets);
    });

    testWidgets('모각코·행사도 같다', (tester) async {
      await tester.pumpScreen(const MeetupScreen(), settle: false);
      await tester.pump();
      expect(find.byType(ListSkeleton), findsOneWidget);
      await tester.pump(mockNetworkDelay);
      await tester.pumpAndSettle();
      expect(find.byType(ListSkeleton), findsNothing);

      await tester.pumpScreen(const EventScreen(), settle: false);
      await tester.pump();
      expect(find.byType(ListSkeleton), findsOneWidget);
      await tester.pump(mockNetworkDelay);
      await tester.pumpAndSettle();
      expect(find.byType(ListSkeleton), findsNothing);
    });
  });

  group('첫 로딩 실패', () {
    testWidgets('빈 화면이 아니라 실패 화면을 세운다', (tester) async {
      final container = await tester.pumpScreen(const CommunityScreen());
      container.read(mockFailureProvider.notifier).set(true);
      await tester.reload(container.read(postPagingProvider.notifier).reload());

      // 서버가 죽었는데 '첫 글을 남겨보세요'가 뜨면 안 된다.
      expect(find.byType(LoadFailure), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(PostCard), findsNothing);
    });

    testWidgets('다시 시도를 누르면 되살아난다', (tester) async {
      final container = await tester.pumpScreen(const CommunityScreen());
      container.read(mockFailureProvider.notifier).set(true);
      await tester.reload(container.read(postPagingProvider.notifier).reload());
      expect(find.byType(LoadFailure), findsOneWidget);

      container.read(mockFailureProvider.notifier).set(false);
      await tester.tap(find.text('다시 시도'));
      await tester.pump(mockNetworkDelay);
      await tester.pumpAndSettle();

      expect(find.byType(LoadFailure), findsNothing);
      expect(find.byType(PostCard), findsWidgets);
    });

    testWidgets('모각코도 같다', (tester) async {
      final container = await tester.pumpScreen(const MeetupScreen());
      container.read(mockFailureProvider.notifier).set(true);
      await tester.reload(
        container.read(meetupPagingProvider.notifier).reload(),
      );

      expect(find.byType(LoadFailure), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('행사도 같다', (tester) async {
      final container = await tester.pumpScreen(const EventScreen());
      container.read(mockFailureProvider.notifier).set(true);
      await tester.reload(
        container.read(eventPagingProvider.notifier).reload(),
      );

      expect(find.byType(LoadFailure), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
    });
  });

  group('다음 쪽 실패', () {
    testWidgets('읽던 것은 남기고 아래에만 다시 시도를 붙인다', (tester) async {
      final container = await tester.pumpScreen(const CommunityScreen());
      await tester.pump(mockNetworkDelay);
      await tester.pumpAndSettle();

      final before = container.read(pagedPostsProvider).items.length;
      expect(before, greaterThan(0));

      container.read(mockFailureProvider.notifier).set(true);
      final loading = container.read(postPagingProvider.notifier).loadMore();
      await tester.pump(mockNetworkDelay);
      await loading;
      await tester.pumpAndSettle();

      // 뒤가 실패했다고 앞까지 지우면 읽던 것이 통째로 사라진다.
      expect(container.read(pagedPostsProvider).items, hasLength(before));
      // 화면 전체를 실패로 덮지 않는다.
      expect(find.byType(LoadFailure), findsNothing);

      // 푸터는 목록 끝이라 스크롤로 지어질 때까지 끌어와야 한다.
      final footer = find.text('더 불러오지 못했어요');
      await tester.dragUntilVisible(
        footer,
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      expect(footer, findsOneWidget);
    });
  });
}
