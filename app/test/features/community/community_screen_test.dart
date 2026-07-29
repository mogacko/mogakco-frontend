import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_test/flutter_test.dart';
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

    testWidgets('지금 보고 있는 지역의 글만 세운다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      expect(find.text('커뮤니티'), findsOneWidget);
      // 기본 지역은 부산이다.
      expect(find.textContaining('Flutter 웹에서 안전영역'), findsOneWidget);
      // 서울 글은 여기 섞이지 않는다.
      expect(find.textContaining('이직 준비 6개월'), findsNothing);
    });

    testWidgets('분류를 고르면 그 분류만 남는다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      await tester.tap(filterPill('모집'));
      await tester.pumpAndSettle();

      expect(find.textContaining('토요일 알고리즘 스터디'), findsOneWidget);
      expect(find.textContaining('Flutter 웹에서 안전영역'), findsNothing);
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

    testWidgets('반응이 많은 글에는 인기 표시가 붙는다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      // 상위 세 편에만 붙는다. 전부 붙으면 표시가 뜻을 잃는다.
      expect(find.text('인기'), findsNWidgets(3));
    });
  });
}
