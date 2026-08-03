import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/community/domain/post.dart';
import 'package:mogacko/shared/data/mock_delay.dart';
import 'package:mogacko/features/community/presentation/post_provider.dart';
import 'package:mogacko/features/community/presentation/post_write_screen.dart';
import 'package:mogacko/shared/widgets/filter_bar.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('글쓰기', () {
    Finder submit() => find.widgetWithText(FilledButton, '올리기');

    testWidgets('제목과 내용이 다 차야 올릴 수 있다', (tester) async {
      await tester.pumpScreen(const PostWriteScreen(board: PostBoard.talk));
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(submit()).onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, '제목만 있음');
      await tester.pumpAndSettle();
      // 제목만으로는 글이 아니다.
      expect(tester.widget<FilledButton>(submit()).onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(1), '내용');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(submit()).onPressed, isNotNull);
    });

    testWidgets('공백만 적은 것은 빈 것으로 친다', (tester) async {
      await tester.pumpScreen(const PostWriteScreen(board: PostBoard.talk));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.enterText(find.byType(TextField).at(1), '   ');
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(submit()).onPressed, isNull);
    });

    testWidgets('이야기 게시판에서만 분류를 고른다', (tester) async {
      await tester.pumpScreen(const PostWriteScreen(board: PostBoard.talk));
      await tester.pumpAndSettle();

      expect(find.byType(FilterBar<PostCategory>), findsOneWidget);
    });

    testWidgets('질문 게시판에는 분류가 없다', (tester) async {
      await tester.pumpScreen(const PostWriteScreen(board: PostBoard.question));
      await tester.pumpAndSettle();

      // 질문은 그 자체로 분류다. 빈 알약 줄을 남기지 않는다.
      expect(find.byType(FilterBar<PostCategory>), findsNothing);
      expect(find.text('질문 글쓰기'), findsOneWidget);
    });

    testWidgets('올리면 목록 맨 앞에 그 글이 선다', (tester) async {
      final container = await tester.pumpScreen(
        const PostWriteScreen(board: PostBoard.talk),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '오늘 처음 나왔습니다');
      await tester.enterText(find.byType(TextField).at(1), '잘 부탁드려요');
      await tester.pumpAndSettle();
      await tester.tap(find.text('회고'));
      await tester.pumpAndSettle();
      await tester.tap(submit());
      await tester.pumpAndSettle();

      final posts = container.read(postFeedProvider);
      expect(posts.first.title, '오늘 처음 나왔습니다');
      expect(posts.first.board, PostBoard.talk);
      expect(posts.first.category, PostCategory.retrospective);
      // 갓 쓴 글에 좋아요가 붙어 있으면 이상하다.
      expect(posts.first.likeCount, 0);
    });

    testWidgets('올린 글이 새로고침으로 사라지지 않는다', (tester) async {
      final container = await tester.pumpScreen(
        const PostWriteScreen(board: PostBoard.talk),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '남아 있어야 하는 글');
      await tester.enterText(find.byType(TextField).at(1), '본문');
      await tester.pumpAndSettle();
      await tester.tap(submit());
      await tester.pumpAndSettle();

      // 목업 왕복은 진짜 타이머라 pump 로 시계를 돌려야 끝난다.
      final refreshed = container.read(postFeedProvider.notifier).refresh();
      await tester.pump(mockNetworkDelay);
      await refreshed;

      final titles = container.read(postFeedProvider).map((post) => post.title);
      expect(titles, contains('남아 있어야 하는 글'));
    });
  });
}
