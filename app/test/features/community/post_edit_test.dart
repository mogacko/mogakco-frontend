import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/comment/domain/comment.dart';
import 'package:mogacko/features/comment/presentation/comment_provider.dart';
import 'package:mogacko/features/community/domain/post.dart';
import 'package:mogacko/features/community/presentation/post_detail_screen.dart';
import 'package:mogacko/features/community/presentation/post_edit_screen.dart';
import 'package:mogacko/features/community/presentation/post_provider.dart';
import 'package:mogacko/shared/widgets/empty_state.dart';

import '../../helpers/pump_app.dart';

void main() {
  /// 내가 쓴 글. 목업에서 evan 이 쓴 것이다.
  const mine = 'busan-t2';

  group('글 고치기', () {
    testWidgets('지금 값이 채워진 채로 열린다', (tester) async {
      final container = await tester.pumpScreen(
        const PostEditScreen(postId: mine),
      );
      await tester.pumpAndSettle();

      final post = container
          .read(postFeedProvider)
          .firstWhere((post) => post.id == mine);
      expect(find.text(post.title), findsOneWidget);
      expect(find.text('글 고치기'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '저장'), findsOneWidget);
    });

    testWidgets('저장하면 본문이 바뀌고 수정됨이 붙는다', (tester) async {
      final container = await tester.pumpScreen(
        const PostEditScreen(postId: mine),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '고친 제목');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      final post = container
          .read(postFeedProvider)
          .firstWhere((post) => post.id == mine);
      expect(post.title, '고친 제목');
      expect(post.isEdited, isTrue);
    });

    testWidgets('고쳐도 쓴 때와 좋아요는 그대로다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final before = container
          .read(postFeedProvider)
          .firstWhere((post) => post.id == mine);

      container
          .read(postFeedProvider.notifier)
          .edit(mine, title: '제목', body: '본문');

      final after = container
          .read(postFeedProvider)
          .firstWhere((post) => post.id == mine);
      // 고쳤다고 목록에서 자리가 옮겨지면 읽던 곳을 잃는다.
      expect(after.createdAt, before.createdAt);
      expect(after.likeCount, before.likeCount);
    });

    testWidgets('게시판은 안 바뀐다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final before = container
          .read(postFeedProvider)
          .firstWhere((post) => post.id == 'busan-q1');

      container
          .read(postFeedProvider.notifier)
          .edit(
            'busan-q1',
            title: '제목',
            body: '본문',
            category: PostCategory.recruit,
          );

      final after = container
          .read(postFeedProvider)
          .firstWhere((post) => post.id == 'busan-q1');
      // 질문으로 올린 글이 이야기로 옮겨 가면 답을 기다리던 사람이 다시
      // 찾을 수 없다. 분류도 질문 게시판에는 붙지 않는다.
      expect(after.board, before.board);
      expect(after.category, isNull);
    });

    testWidgets('없는 글을 고치려 하면 없다고 말한다', (tester) async {
      await tester.pumpScreen(const PostEditScreen(postId: '없는글'));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });
  });

  group('글 삭제', () {
    testWidgets('지우면 목록에서 빠지고 댓글도 함께 사라진다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      const thread = (target: CommentTarget.post, id: mine);
      expect(container.read(commentsOfProvider(thread)), isNotEmpty);

      container.read(postFeedProvider.notifier).remove(mine);

      expect(
        container.read(postFeedProvider).map((post) => post.id),
        isNot(contains(mine)),
      );
      // 남겨두면 어디에도 안 붙은 댓글이 개수만 올리며 떠돈다.
      expect(container.read(commentsOfProvider(thread)), isEmpty);
      expect(container.read(postCommentCountsProvider)[mine], isNull);
    });
  });

  group('댓글 고치기', () {
    testWidgets('내 댓글만 고쳐진다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final others = container
          .read(commentListProvider)
          .firstWhere((comment) => !comment.isMine);

      container.read(commentListProvider.notifier).edit(others.id, '바꿔치기');

      final after = container
          .read(commentListProvider)
          .firstWhere((comment) => comment.id == others.id);
      expect(after.body, others.body);
      expect(after.isEdited, isFalse);
    });

    testWidgets('고치면 수정됨이 붙는다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final mineComment = container
          .read(commentListProvider)
          .firstWhere((comment) => comment.isMine);

      container
          .read(commentListProvider.notifier)
          .edit(mineComment.id, '고친 댓글');

      final after = container
          .read(commentListProvider)
          .firstWhere((comment) => comment.id == mineComment.id);
      expect(after.body, '고친 댓글');
      expect(after.isEdited, isTrue);
      // 쓴 때는 그대로여야 대화 순서가 안 흔들린다.
      expect(after.createdAt, mineComment.createdAt);
    });

    testWidgets('빈 내용으로는 안 고쳐진다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final mineComment = container
          .read(commentListProvider)
          .firstWhere((comment) => comment.isMine);

      container.read(commentListProvider.notifier).edit(mineComment.id, '   ');

      // 비우는 건 지우는 것과 다르다. 지우려면 삭제가 따로 있다.
      final after = container
          .read(commentListProvider)
          .firstWhere((comment) => comment.id == mineComment.id);
      expect(after.body, mineComment.body);
    });
  });

  group('내 글의 더보기', () {
    testWidgets('내 글에는 고치기가, 남의 글에는 신고가 붙는다', (tester) async {
      await tester.pumpScreen(const PostDetailScreen(postId: mine));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('더보기'));
      await tester.pumpAndSettle();

      expect(find.text('글 고치기'), findsOneWidget);
      expect(find.text('글 삭제'), findsOneWidget);
      expect(find.textContaining('신고'), findsNothing);
    });

    testWidgets('남의 글에는 고치기가 없다', (tester) async {
      await tester.pumpScreen(const PostDetailScreen(postId: 'busan-t1'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('더보기'));
      await tester.pumpAndSettle();

      expect(find.text('글 고치기'), findsNothing);
      expect(find.textContaining('신고'), findsWidgets);
    });
  });
}
