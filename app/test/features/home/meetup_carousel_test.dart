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
