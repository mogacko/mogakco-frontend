import 'package:flutter/material.dart';
import 'package:mogacko/core/theme/app_spacing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/comment/domain/comment.dart';
import 'package:mogacko/features/comment/presentation/comment_provider.dart';
import 'package:mogacko/features/community/presentation/post_detail_screen.dart';
import 'package:mogacko/features/safety/domain/report.dart';
import 'package:mogacko/features/safety/presentation/safety_provider.dart';

import '../../helpers/pump_app.dart';

void main() {
  /// 질문 글. 목업에서 답글 스레드가 달려 있다.
  const thread = (target: CommentTarget.post, id: 'busan-q1');

  group('대댓글', () {
    testWidgets('답글이 부모 밑에 붙는다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final nodes = container.read(commentTreeProvider(thread));
      final parent = nodes.firstWhere((node) => node.replies.isNotEmpty);

      expect(parent.replies, hasLength(2));
      // 답글은 부모 밑에서 시간순이다.
      expect(
        parent.replies.first.createdAt.isBefore(parent.replies.last.createdAt),
        isTrue,
      );
      // 부모 목록에는 답글이 섞이지 않는다.
      expect(nodes.every((node) => !node.comment.isReply), isTrue);
    });

    testWidgets('새 답글은 목록 맨 아래가 아니라 부모 밑으로 간다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final nodes = container.read(commentTreeProvider(thread));
      final first = nodes.first.comment;
      expect(nodes.first.replies, isEmpty);

      container
          .read(commentListProvider.notifier)
          .add(thread, '여기에 답글', parentId: first.id);

      final after = container.read(commentTreeProvider(thread));
      expect(after.first.replies.single.body, '여기에 답글');
      // 부모 줄 수는 그대로다. 답글이 새 스레드를 만들지 않는다.
      expect(after.length, nodes.length);
    });

    testWidgets('답글에 답글을 달아도 한 단계에 머문다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final parent = container
          .read(commentTreeProvider(thread))
          .firstWhere((node) => node.replies.isNotEmpty);
      final reply = parent.replies.first;

      // 화면은 답글에 '답글' 버튼을 두지 않는다. 데이터로 들어오더라도
      // 부모의 부모까지 거슬러 붙어야 3단계가 안 생긴다.
      container
          .read(commentListProvider.notifier)
          .add(thread, '답글의 답글', parentId: reply.parentId);

      final after = container
          .read(commentTreeProvider(thread))
          .firstWhere((node) => node.comment.id == parent.comment.id);
      expect(after.replies.last.body, '답글의 답글');
      expect(after.replies.last.parentId, parent.comment.id);
    });

    testWidgets('댓글 수에 답글도 들어간다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final before = container.read(postCommentCountsProvider)['busan-q1']!;
      final parent = container.read(commentTreeProvider(thread)).first.comment;

      container
          .read(commentListProvider.notifier)
          .add(thread, '답글', parentId: parent.id);

      // 목록에 '5'라 적고 열었더니 여섯 개면 어긋난다.
      expect(container.read(postCommentCountsProvider)['busan-q1'], before + 1);
    });
  });

  group('답글이 달린 댓글 지우기', () {
    testWidgets('자리는 남고 답글은 그대로다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // 목업의 답글 달린 부모는 내 댓글(c3)이다.
      final parent = container
          .read(commentTreeProvider(thread))
          .firstWhere((node) => node.replies.isNotEmpty);
      expect(parent.comment.isMine, isTrue);

      container.read(commentListProvider.notifier).remove(parent.comment.id);

      final after = container
          .read(commentTreeProvider(thread))
          .firstWhere((node) => node.comment.id == parent.comment.id);
      // 없애 버리면 밑에 달린 답글이 무슨 말에 대한 것인지 알 수 없게 된다.
      expect(after.masked, isTrue);
      expect(after.replies, hasLength(2));
    });

    testWidgets('지워진 자리는 개수에서 빠진다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final parent = container
          .read(commentTreeProvider(thread))
          .firstWhere((node) => node.replies.isNotEmpty);
      final before = container.read(postCommentCountsProvider)['busan-q1']!;

      container.read(commentListProvider.notifier).remove(parent.comment.id);

      expect(container.read(postCommentCountsProvider)['busan-q1'], before - 1);
    });

    testWidgets('답글이 없으면 그냥 사라진다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final lonely = container
          .read(commentListProvider)
          .firstWhere(
            (comment) =>
                comment.isMine &&
                comment.targetId == 'busan-q2' &&
                !comment.isReply,
          );

      container.read(commentListProvider.notifier).remove(lonely.id);

      expect(
        container.read(commentListProvider).map((comment) => comment.id),
        isNot(contains(lonely.id)),
      );
    });
  });

  group('가려진 부모', () {
    testWidgets('신고해도 답글이 있으면 자리가 남는다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final parent = container
          .read(commentTreeProvider(thread))
          .firstWhere((node) => node.replies.isNotEmpty);

      container
          .read(reportsProvider.notifier)
          .add(
            target: ReportTarget.comment,
            targetId: parent.comment.id,
            reason: ReportReason.abuse,
          );

      final after = container
          .read(commentTreeProvider(thread))
          .where((node) => node.comment.id == parent.comment.id);
      // 답글 쓴 사람은 죄가 없다. 그 말들은 남아야 한다.
      expect(after, hasLength(1));
      expect(after.single.masked, isTrue);
      expect(after.single.replies, hasLength(2));
    });

    testWidgets('차단한 사람의 답글은 그냥 빠진다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final parent = container
          .read(commentTreeProvider(thread))
          .firstWhere((node) => node.replies.isNotEmpty);
      final other = parent.replies.firstWhere((reply) => !reply.isMine);

      container.read(blockedProvider.notifier).block(other.author);

      final after = container
          .read(commentTreeProvider(thread))
          .firstWhere((node) => node.comment.id == parent.comment.id);
      // 답글 밑에는 아무것도 매달려 있지 않아 자리를 남길 이유가 없다.
      expect(after.replies.map((reply) => reply.id), isNot(contains(other.id)));
    });
  });

  group('배치', () {
    /// 화면 폭. 여기서 오른쪽 여백을 재려면 크기를 고정해야 한다.
    const width = 390.0;

    testWidgets('더보기는 부모든 답글이든 오른쪽 끝에 선다', (tester) async {
      tester.view
        ..physicalSize = const Size(width, 844)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpScreen(const PostDetailScreen(postId: 'busan-q1'));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.bySemanticsLabel('댓글 신고').first,
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Flexible 과 Spacer 를 한 줄에 같이 두면 빈 폭을 반씩 나눠 가져서
      // '⋯'가 가운데쯤 선다. 들여쓴 답글도 같은 선에 맞아야 한다.
      final menus = <Finder>[
        find.bySemanticsLabel('댓글 신고'),
        find.bySemanticsLabel('내 댓글 더보기'),
      ];

      for (final menu in menus) {
        for (final element in menu.evaluate()) {
          final box = element.renderObject! as RenderBox;
          final right =
              box.localToGlobal(Offset.zero).dx + box.size.width;
          expect(
            right,
            closeTo(width - AppSpacing.screenHorizontal, 1),
            reason: '더보기가 오른쪽 여백에 안 붙었다',
          );
        }
      }
    });
  });

  group('화면', () {
    testWidgets('답글을 그 자리에서 쓴다', (tester) async {
      final container = await tester.pumpScreen(
        const PostDetailScreen(postId: 'busan-q1'),
      );
      await tester.pumpAndSettle();

      final before = container.read(commentListProvider).length;

      await tester.dragUntilVisible(
        find.text('답글').first,
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('답글').first);
      await tester.pumpAndSettle();

      // 화면 아래 고정 입력줄이 아니라 그 자리에 열린다.
      expect(find.widgetWithText(TextField, '답글을 남겨주세요'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, '답글을 남겨주세요'),
        '여기서 바로',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('답글 등록'));
      await tester.pumpAndSettle();

      expect(container.read(commentListProvider).length, before + 1);
      expect(
        container.read(commentListProvider).last.parentId,
        isNotNull,
      );
    });
  });
}
