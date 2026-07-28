import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/home/domain/meetup.dart';
import 'package:mogacko/features/home/presentation/widgets/meetup_carousel.dart';
import 'package:mogacko/shared/domain/chapter.dart';

import '../../helpers/pump_app.dart';

/// 목록을 직접 넘길 수 있어 provider를 갈아끼우지 않고 상태를 만들 수 있다.
Meetup _meetup({
  String id = 'a',
  int participantCount = 3,
  int capacity = 8,
  bool isJoined = false,
}) {
  return Meetup(
    id: id,
    chapter: Chapter.busan,
    placeName: '카페 오리진',
    address: '부산광역시 해운대구 우동',
    participantCount: participantCount,
    capacity: capacity,
    isJoined: isJoined,
  );
}

void main() {
  group('MeetupCarousel', () {
    testWidgets('모임이 없으면 빈 상태를 보여준다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(meetups: const [], onToggleJoin: (_) {}),
      );

      expect(find.text('아직 열린 모임이 없어요'), findsOneWidget);
    });

    testWidgets('장소·주소·인원만 보여준다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(meetups: [_meetup()], onToggleJoin: (_) {}),
      );

      expect(find.text('카페 오리진'), findsOneWidget);
      expect(find.text('해운대구 우동'), findsOneWidget);
      expect(find.text('3 / 8'), findsOneWidget);

      // 인원이 곧 남은 자리를 말해주므로 따로 안내하지 않는다.
      expect(find.textContaining('자리 남음'), findsNothing);
    });

    testWidgets('정원이 차면 신청 버튼이 잠긴다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_meetup(participantCount: 8)],
          onToggleJoin: (_) {},
        ),
      );

      // 마감은 버튼 상태로만 드러낸다.
      expect(find.text('마감'), findsOneWidget);
      expect(find.text('모집 마감'), findsNothing);

      // 잠긴 버튼은 탭해도 콜백이 돌지 않는다.
      var called = false;
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_meetup(participantCount: 8)],
          onToggleJoin: (_) => called = true,
        ),
      );
      await tester.tap(find.text('마감'));
      await tester.pumpAndSettle();
      expect(called, isFalse);
    });

    testWidgets('정원이 찼어도 이미 신청했다면 취소할 수 있다', (tester) async {
      var called = false;
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_meetup(participantCount: 8, isJoined: true)],
          onToggleJoin: (_) => called = true,
        ),
      );

      expect(find.text('참여 취소'), findsOneWidget);
      await tester.tap(find.text('참여 취소'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('첫 장에서도 좌우로 이웃 카드가 걸쳐 보인다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [
            _meetup(id: 'a'),
            _meetup(id: 'b'),
            _meetup(id: 'c'),
          ],
          onToggleJoin: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // 화면 폭보다 좁은 카드가 3장 얹혀 있으면 양옆이 걸친 상태다.
      expect(find.byType(PageView), findsOneWidget);
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller!.viewportFraction, lessThan(1.0));
      // 무한 순환이라 총 개수가 정해져 있지 않다.
      expect(pageView.childrenDelegate.estimatedChildCount, isNull);
    });

    testWidgets('끝까지 넘겨도 처음으로 이어진다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [
            _meetup(id: 'a'),
            _meetup(id: 'b'),
          ],
          onToggleJoin: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // 항목 수보다 많이 넘겨도 끝에 닿지 않고 카드가 계속 나온다.
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('카페 오리진'), findsWidgets);
    });

    testWidgets('한 장뿐이면 순환시키지 않는다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(meetups: [_meetup()], onToggleJoin: (_) {}),
      );
      await tester.pumpAndSettle();

      // 같은 카드만 반복될 뿐이라 개수를 고정한다.
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.childrenDelegate.estimatedChildCount, 1);
    });

    testWidgets('카드가 여러 장이면 페이지 점을 그린다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [
            _meetup(id: 'a'),
            _meetup(id: 'b'),
            _meetup(id: 'c'),
          ],
          onToggleJoin: (_) {},
        ),
      );

      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('다크 모드에서도 오버플로 없이 그려진다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(meetups: [_meetup()], onToggleJoin: (_) {}),
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
