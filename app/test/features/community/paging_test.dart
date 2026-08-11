import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/community/domain/post.dart';
import 'package:mogacko/features/community/presentation/community_screen.dart';
import 'package:mogacko/features/community/presentation/post_provider.dart';
import 'package:mogacko/features/community/presentation/widgets/post_card.dart';
import 'package:mogacko/features/event/domain/event.dart';
import 'package:mogacko/features/event/presentation/event_provider.dart';
import 'package:mogacko/features/event/presentation/event_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/meetup/presentation/meetup_screen.dart';
import 'package:mogacko/shared/data/mock_delay.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('글 목록 페이징', () {
    testWidgets('처음에는 한 쪽만 받는다', (tester) async {
      final container = await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      final all = container.read(visiblePostsProvider).length;
      expect(all, greaterThan(PostPaging.pageSize));

      final paged = container.read(pagedPostsProvider);
      expect(paged.items, hasLength(PostPaging.pageSize));
      expect(paged.hasMore, isTrue);
    });

    testWidgets('더 받으면 앞의 것 뒤에 붙는다', (tester) async {
      final container = await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      final first = container.read(pagedPostsProvider).items;

      final loading = container.read(postPagingProvider.notifier).loadMore();
      await tester.pump(mockNetworkDelay);
      await loading;

      final after = container.read(pagedPostsProvider).items;
      expect(after.length, first.length + PostPaging.pageSize);
      // 앞부분은 그대로여야 읽던 자리를 잃지 않는다.
      expect(after.take(first.length).map((p) => p.id), first.map((p) => p.id));
    });

    testWidgets('끝까지 받으면 더 없다고 표시된다', (tester) async {
      final container = await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      final total = container.read(visiblePostsProvider).length;
      while (container.read(pagedPostsProvider).hasMore) {
        final loading = container.read(postPagingProvider.notifier).loadMore();
        await tester.pump(mockNetworkDelay);
        await loading;
      }

      final paged = container.read(pagedPostsProvider);
      expect(paged.items, hasLength(total));
      expect(paged.hasMore, isFalse);
    });

    testWidgets('좋아요를 눌러도 받아 둔 쪽이 줄지 않는다', (tester) async {
      final container = await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      final loading = container.read(postPagingProvider.notifier).loadMore();
      await tester.pump(mockNetworkDelay);
      await loading;
      final before = container.read(pagedPostsProvider).items.length;

      // 목록을 통째로 들고 있으면 원본이 바뀔 때 페이지가 처음으로 되돌아간다.
      container
          .read(postFeedProvider.notifier)
          .toggleLike(container.read(pagedPostsProvider).items.first.id);
      await tester.pumpAndSettle();

      expect(container.read(pagedPostsProvider).items, hasLength(before));
    });

    testWidgets('게시판을 바꾸면 처음부터 다시 받는다', (tester) async {
      final container = await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      final loading = container.read(postPagingProvider.notifier).loadMore();
      await tester.pump(mockNetworkDelay);
      await loading;
      expect(
        container.read(pagedPostsProvider).items.length,
        greaterThan(PostPaging.pageSize),
      );

      // 이야기 스무 개까지 보다 질문으로 옮겼는데 스무 개가 차 있으면
      // 아래가 텅 빈 것처럼 보인다.
      container.read(postBoardProvider.notifier).select(PostBoard.question);
      await tester.pumpAndSettle();

      expect(
        container.read(pagedPostsProvider).items.length,
        lessThanOrEqualTo(PostPaging.pageSize),
      );
    });

    testWidgets('새로고침하면 페이지도 처음으로 간다', (tester) async {
      final container = await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      final loading = container.read(postPagingProvider.notifier).loadMore();
      await tester.pump(mockNetworkDelay);
      await loading;

      container.read(postPagingProvider.notifier).reset();
      await tester.pumpAndSettle();

      expect(
        container.read(pagedPostsProvider).items,
        hasLength(PostPaging.pageSize),
      );
    });

    testWidgets('화면에도 한 쪽만 그려진다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      // 슬리버가 화면 밖까지 미리 짓기 때문에 실제로 지어진 카드 수로 센다.
      expect(
        find.byType(PostCard).evaluate().length,
        lessThanOrEqualTo(PostPaging.pageSize),
      );
    });
  });
  group('모각코 목록 페이징', () {
    testWidgets('처음엔 한 쪽만, 더 받으면 뒤에 붙는다', (tester) async {
      final container = await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      expect(
        container.read(filteredMeetupsProvider).length,
        greaterThan(MeetupPaging.pageSize),
      );
      final first = container.read(pagedMeetupsProvider);
      expect(first.items, hasLength(MeetupPaging.pageSize));
      expect(first.hasMore, isTrue);

      final loading = container.read(meetupPagingProvider.notifier).loadMore();
      await tester.pump(mockNetworkDelay);
      await loading;

      final after = container.read(pagedMeetupsProvider);
      expect(after.items.length, greaterThan(first.items.length));
      expect(
        after.items.take(first.items.length).map((m) => m.id),
        first.items.map((m) => m.id),
      );
    });

    testWidgets('참여를 눌러도 받아 둔 쪽이 줄지 않는다', (tester) async {
      final container = await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      final loading = container.read(meetupPagingProvider.notifier).loadMore();
      await tester.pump(mockNetworkDelay);
      await loading;
      final before = container.read(pagedMeetupsProvider).items.length;

      final target = container.read(pagedMeetupsProvider).items.first;
      container
          .read(meetupListProvider.notifier)
          .toggleSession(target.id, target.sessions.first.id);
      await tester.pumpAndSettle();

      expect(container.read(pagedMeetupsProvider).items, hasLength(before));
    });

    testWidgets('필터를 바꾸면 처음부터 다시 받는다', (tester) async {
      final container = await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      final loading = container.read(meetupPagingProvider.notifier).loadMore();
      await tester.pump(mockNetworkDelay);
      await loading;

      container.read(meetupFilterProvider.notifier).select(MeetupFilter.joined);
      await tester.pumpAndSettle();

      expect(
        container.read(pagedMeetupsProvider).items.length,
        lessThanOrEqualTo(MeetupPaging.pageSize),
      );
    });
  });

  group('행사 목록 페이징', () {
    testWidgets('처음엔 한 쪽만, 더 받으면 뒤에 붙는다', (tester) async {
      final container = await tester.pumpScreen(const EventScreen());
      await tester.pumpAndSettle();

      expect(
        container.read(visibleEventsProvider).length,
        greaterThan(EventPaging.pageSize),
      );
      final first = container.read(pagedEventsProvider);
      expect(first.items, hasLength(EventPaging.pageSize));

      final loading = container.read(eventPagingProvider.notifier).loadMore();
      await tester.pump(mockNetworkDelay);
      await loading;

      final after = container.read(pagedEventsProvider);
      expect(after.items.length, greaterThan(first.items.length));
      expect(
        after.items.take(first.items.length).map((e) => e.id),
        first.items.map((e) => e.id),
      );
    });

    testWidgets('종류를 바꾸면 처음부터 다시 받는다', (tester) async {
      final container = await tester.pumpScreen(const EventScreen());
      await tester.pumpAndSettle();

      final loading = container.read(eventPagingProvider.notifier).loadMore();
      await tester.pump(mockNetworkDelay);
      await loading;

      container.read(eventFilterProvider.notifier).select(EventKind.seminar);
      await tester.pumpAndSettle();

      expect(
        container.read(pagedEventsProvider).items.length,
        lessThanOrEqualTo(EventPaging.pageSize),
      );
    });
  });
}
