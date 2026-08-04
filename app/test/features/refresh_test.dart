import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/comment/domain/comment.dart';
import 'package:mogacko/features/comment/presentation/comment_provider.dart';
import 'package:mogacko/features/community/presentation/post_provider.dart';
import 'package:mogacko/features/event/presentation/event_provider.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';

/// 새로고침은 서버에서 다시 받아오는 자리다. 목업을 다시 읽는 지금도 내가
/// 눌러 둔 것까지 되돌아가면 안 된다. 새로고침이 되돌리기처럼 보인다.
///
/// 목업에 미리 켜 둔 항목이 있어서 한쪽으로만 맞추면 어긋난다. 켠 것과 끈 것을
/// 모두 확인한다.
void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('커뮤니티', () {
    test('새로 누른 좋아요가 새로고침 후에도 남는다', () async {
      final container = makeContainer();
      // busan-q1 은 목업에서 눌려 있지 않다.
      container.read(postFeedProvider.notifier).toggleLike('busan-q1');

      await container.read(postFeedProvider.notifier).refresh();

      final post = container
          .read(postFeedProvider)
          .firstWhere((post) => post.id == 'busan-q1');
      expect(post.isLiked, isTrue);
      expect(post.likeCount, 13);
    });

    test('취소한 좋아요가 새로고침으로 되살아나지 않는다', () async {
      final container = makeContainer();
      // busan-t1 은 목업에서 이미 눌려 있다.
      container.read(postFeedProvider.notifier).toggleLike('busan-t1');

      await container.read(postFeedProvider.notifier).refresh();

      final post = container
          .read(postFeedProvider)
          .firstWhere((post) => post.id == 'busan-t1');
      expect(post.isLiked, isFalse);
      expect(post.likeCount, 46);
    });
  });

  group('댓글', () {
    const thread = (target: CommentTarget.post, id: 'busan-t1');

    test('방금 단 댓글이 새로고침 후에도 남는다', () async {
      final container = makeContainer();
      container.read(commentListProvider.notifier).add(thread, '축하드려요');

      await container.read(commentListProvider.notifier).refresh();

      final bodies = container
          .read(commentsOfProvider(thread))
          .map((comment) => comment.body);
      expect(bodies, contains('축하드려요'));
    });

    test('지운 댓글이 새로고침으로 되살아나지 않는다', () async {
      final container = makeContainer();
      // 목업에 내가 쓴 댓글이 하나 있다.
      final mine = container
          .read(commentsOfProvider(thread))
          .firstWhere((comment) => comment.isMine);
      container.read(commentListProvider.notifier).remove(mine.id);

      await container.read(commentListProvider.notifier).refresh();

      final ids = container
          .read(commentsOfProvider(thread))
          .map((comment) => comment.id);
      expect(ids, isNot(contains(mine.id)));
    });

    test('남의 댓글은 지워지지 않는다', () async {
      final container = makeContainer();
      final theirs = container
          .read(commentsOfProvider(thread))
          .firstWhere((comment) => !comment.isMine);

      container.read(commentListProvider.notifier).remove(theirs.id);

      final ids = container
          .read(commentsOfProvider(thread))
          .map((comment) => comment.id);
      expect(ids, contains(theirs.id));
    });
  });

  group('모각코', () {
    test('새로 신청한 날이 새로고침 후에도 남는다', () async {
      final container = makeContainer();
      container
          .read(meetupListProvider.notifier)
          // busan-4 는 접힌 모임이라 신청이 막힌다. 열려 있는 자리를 쓴다.
          .toggleSession('busan-1', 'busan-1-sun');

      await container.read(meetupListProvider.notifier).refresh();

      final session = container
          .read(meetupListProvider)
          .expand((meetup) => meetup.sessions)
          .firstWhere((session) => session.id == 'busan-1-sun');
      expect(session.isJoined, isTrue);
    });

    test('취소한 날이 새로고침으로 되살아나지 않는다', () async {
      final container = makeContainer();
      // busan-3-fri 는 목업에서 이미 신청돼 있다.
      container
          .read(meetupListProvider.notifier)
          .toggleSession('busan-3', 'busan-3-fri');

      await container.read(meetupListProvider.notifier).refresh();

      final session = container
          .read(meetupListProvider)
          .expand((meetup) => meetup.sessions)
          .firstWhere((session) => session.id == 'busan-3-fri');
      expect(session.isJoined, isFalse);
    });
  });

  group('행사', () {
    test('새로 신청한 행사가 새로고침 후에도 남는다', () async {
      final container = makeContainer();
      container.read(eventListProvider.notifier).toggleApply('busan-e1');

      await container.read(eventListProvider.notifier).refresh();

      final event = container
          .read(eventListProvider)
          .firstWhere((event) => event.id == 'busan-e1');
      expect(event.isApplied, isTrue);
      expect(event.applicantCount, 28);
    });

    test('취소한 행사가 새로고침으로 되살아나지 않는다', () async {
      final container = makeContainer();
      // busan-e2 는 목업에서 이미 신청돼 있다.
      container.read(eventListProvider.notifier).toggleApply('busan-e2');

      await container.read(eventListProvider.notifier).refresh();

      final event = container
          .read(eventListProvider)
          .firstWhere((event) => event.id == 'busan-e2');
      expect(event.isApplied, isFalse);
      expect(event.applicantCount, 17);
    });
  });
}
