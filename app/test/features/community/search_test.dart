import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/community/presentation/post_provider.dart';
import 'package:mogacko/features/community/presentation/search_screen.dart';
import 'package:mogacko/features/community/presentation/widgets/post_card.dart';
import 'package:mogacko/shared/domain/chapter.dart';
import 'package:mogacko/shared/widgets/empty_state.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('글 검색', () {
    testWidgets('치기 전에는 아무것도 세우지 않는다', (tester) async {
      await tester.pumpScreen(const SearchScreen());
      await tester.pumpAndSettle();

      // 키보드가 이미 올라와 있어 무엇을 할 자리인지 더 말할 필요가 없다.
      expect(find.byType(PostCard), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('제목으로 찾는다', (tester) async {
      final container = await tester.pumpScreen(const SearchScreen());
      await tester.pumpAndSettle();

      final target = container
          .read(chapterPostsProvider)
          .firstWhere((post) => post.title.contains('사이드'));

      await tester.enterText(find.byType(TextField), '사이드');
      await tester.pumpAndSettle();

      expect(find.text(target.title), findsOneWidget);
    });

    testWidgets('게시판을 가리지 않고 찾는다', (tester) async {
      final container = await tester.pumpScreen(const SearchScreen());
      await tester.pumpAndSettle();

      final boards = container
          .read(searchedPostsProvider('.'))
          .map((post) => post.board)
          .toSet();

      // 마침표는 목업 본문 거의 모두에 있다. 게시판이 하나로 좁혀지면 그건
      // 지금 보고 있는 게시판만 뒤졌다는 뜻이다.
      expect(boards.length, greaterThan(1));
    });

    testWidgets('대소문자를 가리지 않는다', (tester) async {
      final container = await tester.pumpScreen(const SearchScreen());
      await tester.pumpAndSettle();

      final lower = container.read(searchedPostsProvider('flutter'));
      final upper = container.read(searchedPostsProvider('Flutter'));

      expect(lower, isNotEmpty);
      expect(lower.length, upper.length);
    });

    testWidgets('다른 지역 글은 걸리지 않는다', (tester) async {
      final container = await tester.pumpScreen(
        const SearchScreen(),
        chapter: Chapter.busan,
      );
      await tester.pumpAndSettle();

      final found = container.read(searchedPostsProvider('.'));
      expect(found, isNotEmpty);
      expect(found.every((post) => post.chapter == Chapter.busan), isTrue);
    });

    testWidgets('결과에 어느 게시판 글인지 붙는다', (tester) async {
      await tester.pumpScreen(const SearchScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '모각코');
      await tester.pumpAndSettle();

      // 분류가 없는 공지도 자리를 비워 두지 않는다.
      expect(find.text('공지'), findsWidgets);
    });

    testWidgets('없으면 없다고 말한다', (tester) async {
      await tester.pumpScreen(const SearchScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '쿠오카');
      await tester.pumpAndSettle();

      expect(find.byType(PostCard), findsNothing);
      expect(find.textContaining('검색 결과가 없어요'), findsOneWidget);
    });

    testWidgets('지우면 결과가 사라진다', (tester) async {
      await tester.pumpScreen(const SearchScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '사이드');
      await tester.pumpAndSettle();
      expect(find.byType(PostCard), findsWidgets);

      await tester.tap(find.byTooltip('지우기'));
      await tester.pumpAndSettle();

      expect(find.byType(PostCard), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });
  });
}
