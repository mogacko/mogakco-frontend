import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/home/domain/meetup.dart';
import 'package:mogacko/features/home/presentation/home_screen.dart';
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
    // 카드 배경에도 로고가 깔려 있어 챕터 워드마크만 따로 골라낸다.
    final chapterLogos = find.byWidgetPredicate(
      (w) => w is MogackoLogo && w.chapter != null,
    );

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

      await tester.tap(find.text('참여 신청').first);
      await tester.pumpAndSettle();

      expect(find.text('6 / 8'), findsOneWidget);
      expect(find.text('5 / 8'), findsNothing);
      // 옆 카드가 걸쳐 보이므로 개수 대신 존재만 확인한다.
      expect(find.text('참여 취소'), findsWidgets);
    });

    testWidgets('다시 누르면 신청이 취소되고 인원이 돌아온다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('참여 신청').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('참여 취소').first);
      await tester.pumpAndSettle();

      expect(find.text('5 / 8'), findsOneWidget);
      expect(find.text('6 / 8'), findsNothing);
    });

    testWidgets('화살표를 누르면 지역 메뉴가 뜬다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      // 닫힌 상태에서는 헤더의 워드마크 하나뿐이다.
      expect(chapterLogos, findsOneWidget);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      // 헤더 1 + 현재 지역을 뺀 나머지 1
      expect(chapterLogos, findsNWidgets(2));
      expect(find.byType(PopupMenuItem<Chapter>), findsOneWidget);
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

    testWidgets('메뉴 항목은 지역명 대신 워드마크로 보여준다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      expect(find.text('서울'), findsNothing);
      expect(find.text('부산'), findsNothing);
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

    testWidgets('열지 않은 지역은 메뉴에 없다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      final items = tester
          .widgetList<PopupMenuItem<Chapter>>(
            find.byType(PopupMenuItem<Chapter>),
          )
          .map((e) => e.value);

      expect(items, everyElement(isIn(Chapter.open)));
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
