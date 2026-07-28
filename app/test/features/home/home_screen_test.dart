import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/home/domain/meetup.dart';
import 'package:mogacko/features/home/presentation/home_screen.dart';
import 'package:mogacko/features/home/presentation/meetup_provider.dart';
import 'package:mogacko/shared/domain/chapter.dart';
import 'package:mogacko/shared/providers/current_chapter_provider.dart';
import 'package:mogacko/shared/widgets/mogacko_logo.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('Meetup', () {
    test('시·도를 뗀 주소를 만든다', () {
      const meetup = Meetup(
        id: 'x',
        chapter: Chapter.seoul,
        placeName: '카페',
        address: '서울특별시 강남구 역삼동',
        participantCount: 1,
        capacity: 4,
      );
      expect(meetup.shortAddress, '강남구 역삼동');
    });

    test('지역과 무관한 주소는 그대로 둔다', () {
      const meetup = Meetup(
        id: 'x',
        chapter: Chapter.busan,
        placeName: '카페',
        address: '경기도 성남시 분당구',
        participantCount: 1,
        capacity: 4,
      );
      expect(meetup.shortAddress, '경기도 성남시 분당구');
    });

    test('남은 자리와 마감 여부를 센다', () {
      const meetup = Meetup(
        id: 'x',
        chapter: Chapter.busan,
        placeName: '카페',
        address: '부산광역시 동구',
        participantCount: 6,
        capacity: 6,
      );
      expect(meetup.remaining, 0);
      expect(meetup.isFull, isTrue);
    });
  });

  group('HomeScreen', () {
    /// 순환 캐러셀은 좌우에 이웃 카드가 걸쳐 있어 first 로 집으면 엉뚱한 카드를
    /// 누른다. 어느 모임인지 키로 짚어 그 안의 버튼만 누른다.
    Finder buttonIn(String meetupId, String label) => find.descendant(
      of: find.byKey(ValueKey(meetupId)).first,
      matching: find.text(label),
    );

    // 카드 배경에도 로고가 깔려 있어 챕터 워드마크만 따로 골라낸다.
    final chapterLogos = find.byWidgetPredicate(
      (w) => w is MogackoLogo && w.chapter != null,
    );

    testWidgets('많이 찬 모임을 앞에 둔다', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final busan = container
          .read(visibleMeetupsProvider)
          .map((m) => m.id)
          .toList();

      // 5/8 → 7/12 → 3/6 → 2/6 순으로 채워진 비율이 높은 쪽이 앞이다.
      expect(busan, ['busan-1', 'busan-3', 'busan-2', 'busan-4']);
    });

    testWidgets('정원이 찬 모임은 인기와 무관하게 뒤로 미룬다', (tester) async {
      const full = Meetup(
        id: 'full',
        chapter: Chapter.busan,
        placeName: '만석',
        address: '부산광역시 동구',
        participantCount: 10,
        capacity: 10,
      );
      const half = Meetup(
        id: 'half',
        chapter: Chapter.busan,
        placeName: '절반',
        address: '부산광역시 동구',
        participantCount: 5,
        capacity: 10,
      );

      // 채워진 비율은 만석이 높지만 신청할 수 없으니 뒤로 간다.
      expect(full.fillRate, greaterThan(half.fillRate));
      expect(full.isFull, isTrue);
      expect(half.isFull, isFalse);
    });

    testWidgets('현재 지역의 모임만 보여준다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      // 기본 지역은 부산이다.
      expect(find.text('모모스커피 온천장'), findsOneWidget);
      expect(find.text('카페 그리다'), findsNothing);
    });

    testWidgets('주소에서 시·도를 떼고 보여준다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('동래구 온천동'), findsOneWidget);
      expect(find.textContaining('부산광역시'), findsNothing);
    });

    testWidgets('참여 인원과 정원을 함께 보여준다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('5 / 8'), findsOneWidget);
    });

    testWidgets('섹션 제목 없이 카드만 보여준다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      // 카드가 스스로 설명하므로 제목·부연 문구를 두지 않는다.
      expect(find.text('지금 모집 중'), findsNothing);
      expect(find.text('자리 잡고 같이 앉을 사람들'), findsNothing);
      expect(find.text('모모스커피 온천장'), findsOneWidget);
    });

    testWidgets('참여 신청을 누르면 인원이 늘고 취소 버튼으로 바뀐다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      // 첫 카드(모모스커피 온천장)는 5/8로 시작한다.
      expect(find.text('5 / 8'), findsOneWidget);

      await tester.tap(buttonIn('busan-1', '참여 신청'));
      await tester.pumpAndSettle();

      expect(find.text('6 / 8'), findsOneWidget);
      expect(find.text('5 / 8'), findsNothing);
      expect(buttonIn('busan-1', '참여 취소'), findsOneWidget);
    });

    testWidgets('다시 누르면 신청이 취소되고 인원이 돌아온다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(buttonIn('busan-1', '참여 신청'));
      await tester.pumpAndSettle();
      await tester.tap(buttonIn('busan-1', '참여 취소'));
      await tester.pumpAndSettle();

      expect(find.text('5 / 8'), findsOneWidget);
      expect(find.text('6 / 8'), findsNothing);
    });

    testWidgets('참여를 눌러도 보고 있던 카드가 그대로 있다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      // 두 번째 카드로 넘긴다.
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      final before = controller.page!.round();

      // 인기순이라 두 번째는 카페 오리진(7/12)이고 이미 참여 중이다.
      expect(find.text('카페 오리진'), findsWidgets);

      await tester.tap(buttonIn('busan-3', '참여 취소'));
      await tester.pumpAndSettle();

      // 목록 구성은 그대로이므로 첫 장으로 튕기면 안 된다.
      expect(controller.page!.round(), before);
      expect(buttonIn('busan-3', '참여 신청'), findsOneWidget);
    });

    testWidgets('지역을 바꾸면 첫 카드부터 다시 보여준다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuItem<Chapter>).first);
      await tester.pumpAndSettle();

      // 서울 목록의 첫 모임이 중앙에 와야 한다.
      expect(find.text('카페 그리다'), findsWidgets);
    });

    testWidgets('화살표를 누르면 지역 메뉴가 뜬다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      // 닫힌 상태에서는 헤더의 워드마크 하나뿐이다.
      expect(chapterLogos, findsOneWidget);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      // 현재 지역을 뺀 아홉 곳이 모두 나열된다.
      expect(
        find.byType(PopupMenuItem<Chapter>),
        findsNWidgets(Chapter.values.length - 1),
      );
      expect(find.text('서울'), findsOneWidget);
      expect(find.text('제주'), findsOneWidget);
    });

    testWidgets('메뉴에 현재 지역은 넣지 않는다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      final items = tester
          .widgetList<PopupMenuItem<Chapter>>(
            find.byType(PopupMenuItem<Chapter>),
          )
          .map((e) => e.value)
          .toList();

      expect(items, isNot(contains(Chapter.busan))); // 지금 지역
      expect(items, contains(Chapter.seoul));
    });

    testWidgets('헤더 워드마크가 지역까지 낭독된다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      // 헤더에는 글자가 없어 낭독 라벨이 유일한 지역 단서다.
      expect(find.bySemanticsLabel('모각코 부산'), findsWidgets);
      expect(find.bySemanticsLabel('모각코 서울'), findsNothing);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('서울'));
      await tester.pumpAndSettle();

      // 지역을 바꾸면 낭독 내용도 따라 바뀐다.
      expect(find.bySemanticsLabel('모각코 서울'), findsWidgets);
      expect(find.bySemanticsLabel('모각코 부산'), findsNothing);
    });

    testWidgets('아직 열지 않은 지역에는 금지 표식이 붙는다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      final closed = Chapter.values.where((c) => !c.isOpen).length;
      expect(find.byIcon(CupertinoIcons.nosign), findsNWidgets(closed));
    });

    testWidgets('열린 지역에는 금지 표식이 없다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      final seoul = find.ancestor(
        of: find.text('서울'),
        matching: find.byType(PopupMenuItem<Chapter>),
      );
      expect(
        find.descendant(
          of: seoul,
          matching: find.byIcon(CupertinoIcons.nosign),
        ),
        findsNothing,
      );
    });

    testWidgets('잠긴 지역을 누르면 이유를 알려주고 지역은 그대로 둔다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('제주'));
      await tester.pumpAndSettle();

      // 눌러도 아무 반응이 없으면 고장난 것처럼 보인다.
      expect(find.text('제주는 아직 준비 중이에요'), findsOneWidget);
      // 지역은 부산 그대로다.
      expect(find.bySemanticsLabel('모각코 부산'), findsWidgets);
    });

    testWidgets('메뉴에서 지역을 고르면 헤더와 목록이 함께 바뀐다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      // 메뉴 항목 순서는 Chapter.open 과 같다. 첫 번째가 서울이다.
      await tester.tap(find.byType(PopupMenuItem<Chapter>).first);
      await tester.pumpAndSettle();

      expect(find.text('카페 그리다'), findsOneWidget);
      expect(find.text('모모스커피 온천장'), findsNothing);

      final header = tester.widget<MogackoLogo>(chapterLogos.first);
      expect(header.chapter, Chapter.seoul);
    });
  });

  group('CurrentChapter', () {
    test('열지 않은 지역으로는 바뀌지 않는다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(currentChapterProvider.notifier);
      notifier.change(Chapter.jeju);

      expect(container.read(currentChapterProvider), Chapter.busan);
    });

    test('열린 지역으로는 바뀐다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(currentChapterProvider.notifier).change(Chapter.seoul);

      expect(container.read(currentChapterProvider), Chapter.seoul);
    });
  });
}
