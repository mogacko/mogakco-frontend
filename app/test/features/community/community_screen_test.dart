import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/core/theme/app_spacing.dart';
import 'package:mogacko/features/community/domain/post.dart';
import 'package:mogacko/features/community/presentation/community_screen.dart';
import 'package:mogacko/shared/widgets/filter_bar.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('CommunityScreen', () {
    /// 분류 이름은 필터 알약과 글 카드 양쪽에 나온다. 필터 쪽만 짚는다.
    Finder filterPill(String label) => find.descendant(
      of: find.byType(FilterBar<PostCategory?>),
      matching: find.text(label),
    );

    /// 상단 제목을 눌러 게시판을 바꾼다.
    Future<void> switchBoard(WidgetTester tester, String label) async {
      await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    testWidgets('이야기 게시판으로 시작하고 지금 지역의 글만 세운다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      expect(find.text('이야기'), findsOneWidget);
      expect(find.textContaining('3개월 만에 첫 사이드 프로젝트'), findsOneWidget);
      // 서울 글은 여기 섞이지 않는다.
      expect(find.textContaining('이직 준비 6개월'), findsNothing);
      // 다른 게시판 글도 섞이지 않는다.
      expect(find.textContaining('Flutter 웹에서 안전영역'), findsNothing);
    });

    testWidgets('제목에서 게시판을 바꾸면 그 게시판만 남는다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      await switchBoard(tester, '질문');

      expect(find.textContaining('Flutter 웹에서 안전영역'), findsOneWidget);
      expect(find.textContaining('3개월 만에 첫 사이드 프로젝트'), findsNothing);
    });

    testWidgets('분류는 이야기 게시판에만 있다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      expect(find.byType(FilterBar<PostCategory?>), findsOneWidget);

      await switchBoard(tester, '질문');

      // 빈 필터 줄을 남기지 않는다.
      expect(find.byType(FilterBar<PostCategory?>), findsNothing);
    });

    testWidgets('공지에는 글쓰기 버튼을 두지 않는다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.square_pencil), findsOneWidget);

      await switchBoard(tester, '공지');

      // 운영진만 올리는 자리라 눌러보고 나서 안 된다는 걸 알게 두지 않는다.
      expect(find.byIcon(CupertinoIcons.square_pencil), findsNothing);
      expect(find.textContaining('8월 정기 모각코 장소'), findsOneWidget);
    });

    testWidgets('분류를 고르면 그 분류만 남는다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      await tester.tap(filterPill('모집'));
      await tester.pumpAndSettle();

      expect(find.textContaining('토요일 알고리즘 스터디'), findsOneWidget);
      expect(find.textContaining('3개월 만에 첫 사이드 프로젝트'), findsNothing);
    });

    testWidgets('글을 열지 않고 목록에서 바로 좋아요를 누른다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      final outline = find.byIcon(CupertinoIcons.heart);
      final filled = find.byIcon(CupertinoIcons.heart_fill);

      // 목업에서 미리 눌러 둔 글이 하나 있다.
      expect(filled, findsOneWidget);

      await tester.tap(outline.first);
      await tester.pumpAndSettle();

      expect(filled, findsNWidgets(2));
    });

    testWidgets('좋아요·댓글 수는 오른쪽 끝에 붙는다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      // Flexible 과 Spacer 를 같이 두면 남는 폭을 반씩 나눠 가져 수치가
      // 안쪽으로 밀린다. 눈으로는 '조금 어긋난' 정도라 놓치기 쉽다.
      // 아이콘 뒤에 숫자가 더 붙으므로 수치 줄 전체를 재야 한다.
      final metricRow = find
          .ancestor(
            of: find.byIcon(CupertinoIcons.bubble_right).first,
            matching: find.byType(Row),
          )
          .first;
      final screen = tester.getRect(find.byType(CommunityScreen));

      expect(
        screen.right - tester.getRect(metricRow).right,
        closeTo(AppSpacing.screenHorizontal, 1),
      );
    });

    testWidgets('반응이 많은 글에만 인기 표시가 붙는다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      // 댓글 수가 실제 댓글을 센 값이 되면서 기준(20)을 넘는 글이 줄었다.
      // 부산에서는 좋아요 47 짜리 회고 하나만 남는다. 기준을 낮춰 개수를
      // 맞추지는 않는다. 좋아요 열두 개짜리 질문을 '인기'라 부를 수는 없다.
      expect(find.text('인기'), findsOneWidget);
    });

    testWidgets('공지는 인기글로 세지 않는다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      // 운영진 글이라 반응이 많이 붙는다. 그대로 두면 인기 자리를 공지가 채운다.
      await switchBoard(tester, '공지');

      expect(find.text('인기'), findsNothing);
    });
  });
}
