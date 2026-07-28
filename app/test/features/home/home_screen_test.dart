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

    testWidgets('헤더의 화살표를 누르면 지역 목록이 펼쳐진다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('서울'), findsNothing);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      expect(find.text('서울'), findsOneWidget);
      expect(find.text('부산'), findsOneWidget);
    });

    testWidgets('지역을 바꾸면 헤더 로고와 목록이 함께 바뀐다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('서울'));
      await tester.pumpAndSettle();

      expect(find.text('카페 그리다'), findsOneWidget);
      expect(find.text('모모스커피 온천장'), findsNothing);

      // 헤더 워드마크도 서울 것으로 교체돼야 한다.
      final logo = tester.widget<MogackoLogo>(find.byType(MogackoLogo).first);
      expect(logo.key, isNull);
    });

    testWidgets('열지 않은 지역은 목록에 없다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
      await tester.pumpAndSettle();

      expect(find.text('대구'), findsNothing);
      expect(find.text('제주'), findsNothing);
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
