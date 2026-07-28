import 'package:flutter/cupertino.dart' show CupertinoIcons;
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
    Meetup make({
      Chapter chapter = Chapter.busan,
      String address = '부산광역시 동래구 온천동',
      List<MeetupSession>? sessions,
    }) {
      return Meetup(
        id: 'x',
        chapter: chapter,
        placeName: '카페',
        address: address,
        host: 'evan',
        sessions:
            sessions ??
            [
              MeetupSession(
                id: 's',
                startsAt: DateTime(2026, 7, 29, 19),
                participantCount: 3,
                capacity: 8,
              ),
            ],
      );
    }

    test('시·도를 뗀 주소를 만든다', () {
      final meetup = make(chapter: Chapter.seoul, address: '서울특별시 강남구 역삼동');
      expect(meetup.shortAddress, '강남구 역삼동');
    });

    test('지역과 무관한 주소는 그대로 둔다', () {
      final meetup = make(address: '경기도 성남시 분당구');
      expect(meetup.shortAddress, '경기도 성남시 분당구');
    });

    test('가장 이른 날을 정렬 기준으로 삼는다', () {
      final meetup = make(
        sessions: [
          MeetupSession(
            id: 'late',
            startsAt: DateTime(2026, 8, 2, 13),
            participantCount: 1,
            capacity: 8,
          ),
          MeetupSession(
            id: 'early',
            startsAt: DateTime(2026, 7, 31, 10),
            participantCount: 1,
            capacity: 8,
          ),
        ],
      );
      expect(meetup.firstStartsAt, DateTime(2026, 7, 31, 10));
    });

    test('모든 날이 차야 마감이다', () {
      final partly = make(
        sessions: [
          MeetupSession(
            id: 'full',
            startsAt: DateTime(2026, 7, 31, 10),
            participantCount: 8,
            capacity: 8,
          ),
          MeetupSession(
            id: 'open',
            startsAt: DateTime(2026, 8, 1, 10),
            participantCount: 2,
            capacity: 8,
          ),
        ],
      );
      expect(partly.isFull, isFalse);
      expect(partly.sessions.first.isFull, isTrue);
    });

    test('하루라도 신청했으면 참여한 모임이다', () {
      final meetup = make(
        sessions: [
          MeetupSession(
            id: 'a',
            startsAt: DateTime(2026, 7, 31, 10),
            participantCount: 1,
            capacity: 8,
          ),
          MeetupSession(
            id: 'b',
            startsAt: DateTime(2026, 8, 1, 10),
            participantCount: 1,
            capacity: 8,
            isJoined: true,
          ),
        ],
      );
      expect(meetup.isJoinedAny, isTrue);
    });

    test('토글은 그 날의 인원만 건드린다', () {
      final before = make(
        sessions: [
          MeetupSession(
            id: 'a',
            startsAt: DateTime(2026, 7, 31, 10),
            participantCount: 3,
            capacity: 8,
          ),
          MeetupSession(
            id: 'b',
            startsAt: DateTime(2026, 8, 1, 10),
            participantCount: 5,
            capacity: 8,
          ),
        ],
      );

      final after = before.toggleSession('a');
      expect(after.sessions[0].participantCount, 4);
      expect(after.sessions[0].isJoined, isTrue);
      expect(after.sessions[1].participantCount, 5);
    });

    test('자리가 찬 날은 새로 신청되지 않는다', () {
      final full = make(
        sessions: [
          MeetupSession(
            id: 'a',
            startsAt: DateTime(2026, 7, 31, 10),
            participantCount: 8,
            capacity: 8,
          ),
        ],
      );
      expect(full.toggleSession('a').sessions.first.participantCount, 8);
    });
  });

  group('MeetupSession', () {
    final now = DateTime(2026, 7, 28, 9);

    MeetupSession at(int afterDays, int hour) => MeetupSession(
      id: 's',
      startsAt: DateTime(now.year, now.month, now.day + afterDays, hour),
      participantCount: 1,
      capacity: 8,
    );

    test('오늘·내일·그 뒤를 나눠 적는다', () {
      expect(at(0, 19).whenLabel(now), '오늘 19:00');
      expect(at(1, 9).whenLabel(now), '내일 09:00');
      expect(at(3, 14).whenLabel(now), '3일 뒤 14:00');
    });

    test('오늘 저녁 모임을 내일로 세지 않는다', () {
      // 기준이 오전 9시여도 같은 날이면 오늘이다.
      expect(at(0, 23).daysFrom(now), 0);
    });
  });

  group('HomeScreen', () {
    /// 순환 캐러셀은 좌우에 이웃 카드가 걸쳐 있어 first 로 집으면 엉뚱한 카드를
    /// 누른다. 어느 모임인지 키로 짚어 그 안의 것만 만진다.
    Finder inCard(String meetupId, String label) => find.descendant(
      of: find.byKey(ValueKey(meetupId)).first,
      matching: find.text(label),
    );

    // 카드 배경에도 로고가 깔려 있어 챕터 워드마크만 따로 골라낸다.
    final chapterLogos = find.byWidgetPredicate(
      (w) => w is MogackoLogo && w.chapter != null,
    );

    testWidgets('오늘 열리는 모임만 세운다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      expect(find.text('오늘의 모각코'), findsOneWidget);

      // 오늘 세션이 있는 모임만 나온다.
      expect(find.text('모모스커피 온천장'), findsWidgets);
      // 오늘 열리지 않는 모임은 빠진다.
      expect(find.text('초량1941'), findsNothing);
    });

    testWidgets('한 카드는 하루만 다룬다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      // 모모스커피는 오늘과 이틀 뒤 이렇게 두 날이 있지만 오늘만 보인다.
      expect(inCard('busan-1', '오늘 10:00'), findsOneWidget);
      expect(inCard('busan-1', '2일 뒤 13:00'), findsNothing);
    });

    testWidgets('참여 신청을 누르면 그 날 인원이 는다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      expect(inCard('busan-1', '5 / 8'), findsOneWidget);

      await tester.tap(inCard('busan-1', '참여 신청'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('참여하기'));
      await tester.pumpAndSettle();

      expect(inCard('busan-1', '6 / 8'), findsOneWidget);
      expect(inCard('busan-1', '참여 취소'), findsOneWidget);
    });

    testWidgets('다시 누르면 참여가 취소된다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(inCard('busan-1', '참여 신청'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('참여하기'));
      await tester.pumpAndSettle();

      await tester.tap(inCard('busan-1', '참여 취소'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '참여 취소'));
      await tester.pumpAndSettle();

      expect(inCard('busan-1', '5 / 8'), findsOneWidget);
    });

    testWidgets('자리가 찬 오늘 모임은 잠긴다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      // 웨이브온은 오늘 6/6 으로 이미 찼다.
      expect(inCard('busan-2', '마감'), findsOneWidget);
    });

    testWidgets('참여를 눌러도 보고 있던 카드가 그대로 있다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      final before = controller.page!.round();

      await tester.tap(inCard('busan-1', '참여 신청'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('참여하기'));
      await tester.pumpAndSettle();

      expect(controller.page!.round(), before);
    });

    testWidgets('오늘 모임이 없는 지역은 다가오는 모임을 세운다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('서울'));
      await tester.pumpAndSettle();

      // 서울은 오늘 열리는 모임이 없다.
      expect(find.text('다가오는 모각코'), findsOneWidget);
      expect(find.text('오늘의 모각코'), findsNothing);
      expect(find.textContaining('내일'), findsWidgets);
    });

    testWidgets('화살표를 누르면 지역 메뉴가 뜬다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      expect(chapterLogos, findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
      await tester.pumpAndSettle();

      expect(
        find.byType(PopupMenuItem<Chapter>),
        findsNWidgets(Chapter.values.length - 1),
      );
    });

    testWidgets('메뉴에 현재 지역은 넣지 않는다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
      await tester.pumpAndSettle();

      final items = tester
          .widgetList<PopupMenuItem<Chapter>>(
            find.byType(PopupMenuItem<Chapter>),
          )
          .map((e) => e.value)
          .toList();

      expect(items, isNot(contains(Chapter.busan)));
      expect(items, contains(Chapter.seoul));
    });

    testWidgets('헤더 워드마크가 지역까지 낭독된다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('모각코 부산'), findsWidgets);
      expect(find.bySemanticsLabel('모각코 서울'), findsNothing);

      await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('서울'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('모각코 서울'), findsWidgets);
    });

    testWidgets('아직 열지 않은 지역에는 금지 표식이 붙는다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
      await tester.pumpAndSettle();

      final closed = Chapter.values.where((c) => !c.isOpen).length;
      expect(find.byIcon(CupertinoIcons.nosign), findsNWidgets(closed));
    });

    testWidgets('잠긴 지역을 누르면 이유를 알려주고 지역은 그대로 둔다', (tester) async {
      await tester.pumpScreen(const HomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('제주'));
      await tester.pumpAndSettle();

      expect(find.text('제주는 아직 준비 중이에요'), findsOneWidget);
      expect(find.bySemanticsLabel('모각코 부산'), findsWidgets);
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
