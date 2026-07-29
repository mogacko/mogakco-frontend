import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/meetup/domain/meetup.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/home/presentation/widgets/meetup_carousel.dart';
import 'package:mogacko/shared/domain/chapter.dart';

import '../../helpers/pump_app.dart';

/// 기준 시각을 고정해야 '오늘/내일' 표기가 흔들리지 않는다.
final _now = DateTime(2026, 7, 28, 9);

MeetupSession _session({
  String id = 's1',
  int afterDays = 1,
  int hour = 19,
  int participantCount = 3,
  int capacity = 8,
  bool isJoined = false,
}) {
  return MeetupSession(
    id: id,
    startsAt: DateTime(_now.year, _now.month, _now.day + afterDays, hour),
    participantCount: participantCount,
    capacity: capacity,
    isJoined: isJoined,
  );
}

/// 캐러셀은 모임과 '그 중 하루'를 함께 받는다.
MeetupOnDay _entry({String id = 'a', MeetupSession? session}) {
  final s = session ?? _session();
  return (
    meetup: Meetup(
      id: id,
      chapter: Chapter.busan,
      placeName: '카페 오리진',
      address: '부산광역시 해운대구 우동',
      host: 'evan',
      sessions: [s],
    ),
    session: s,
  );
}

void main() {
  group('MeetupCarousel', () {
    testWidgets('모임이 없으면 빈 상태를 보여준다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: const [],
          now: _now,
          onToggleSession: (_, _) {},
        ),
      );

      expect(find.text('아직 열린 모임이 없어요'), findsOneWidget);
    });

    testWidgets('장소·주소와 그 날의 시각·인원을 보여준다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_entry(session: _session(afterDays: 1, hour: 10))],
          now: _now,
          onToggleSession: (_, _) {},
        ),
      );

      expect(find.text('카페 오리진'), findsOneWidget);
      expect(find.text('해운대구 우동'), findsOneWidget);
      expect(find.text('내일 10:00'), findsOneWidget);
      expect(find.text('3 / 8'), findsOneWidget);
    });

    testWidgets('누가 열었는지 보여준다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_entry()],
          now: _now,
          onToggleSession: (_, _) {},
        ),
      );

      expect(find.text('evan'), findsOneWidget);
    });

    testWidgets('오늘 열리는 날은 오늘로 적는다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_entry(session: _session(afterDays: 0, hour: 19))],
          now: _now,
          onToggleSession: (_, _) {},
        ),
      );

      expect(find.text('오늘 19:00'), findsOneWidget);
    });

    testWidgets('참여를 누르면 어느 모임의 어느 날인지 알려준다', (tester) async {
      String? tappedMeetup;
      String? tappedSession;

      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [
            _entry(
              id: 'busan-1',
              session: _session(id: 'sat'),
            ),
          ],
          now: _now,
          onToggleSession: (meetupId, sessionId) {
            tappedMeetup = meetupId;
            tappedSession = sessionId;
          },
        ),
      );

      await tester.tap(find.text('참여 신청'));
      await tester.pumpAndSettle();

      // 바로 신청되지 않고 일정을 한 번 더 보여준다.
      expect(find.text('이 일정으로 참여할까요?'), findsOneWidget);
      expect(tappedMeetup, isNull);

      await tester.tap(find.text('참여하기'));
      await tester.pumpAndSettle();

      expect(tappedMeetup, 'busan-1');
      expect(tappedSession, 'sat');
    });

    testWidgets('확인 창에서 닫으면 아무 일도 일어나지 않는다', (tester) async {
      var called = false;
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_entry()],
          now: _now,
          onToggleSession: (_, _) => called = true,
        ),
      );

      await tester.tap(find.text('참여 신청'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.text('참여 신청'), findsOneWidget);
    });

    testWidgets('확인은 시트로 올라온다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_entry()],
          now: _now,
          onToggleSession: (_, _) {},
        ),
      );

      await tester.tap(find.text('참여 신청'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      // 주 버튼과 물러날 길이 함께 있어야 한다.
      expect(find.widgetWithText(FilledButton, '참여하기'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '닫기'), findsOneWidget);
    });

    testWidgets('시트에 모임장까지 함께 보여준다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_entry()],
          now: _now,
          onToggleSession: (_, _) {},
        ),
      );

      await tester.tap(find.text('참여 신청'));
      await tester.pumpAndSettle();

      // 카드에 하나, 시트에 하나.
      expect(find.text('evan'), findsNWidgets(2));
    });

    testWidgets('확인 창에 장소와 일정을 함께 보여준다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_entry(session: _session(afterDays: 0, hour: 19))],
          now: _now,
          onToggleSession: (_, _) {},
        ),
      );

      await tester.tap(find.text('참여 신청'));
      await tester.pumpAndSettle();

      // 어디서 언제 모이는지 보고 결정하게 한다.
      expect(find.text('카페 오리진'), findsWidgets);
      expect(find.text('해운대구 우동'), findsWidgets);
      expect(find.text('오늘 19:00'), findsWidgets);
    });

    testWidgets('이미 신청한 날은 취소로 보인다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_entry(session: _session(isJoined: true))],
          now: _now,
          onToggleSession: (_, _) {},
        ),
      );

      expect(find.text('참여 중'), findsOneWidget);
      expect(find.text('참여 신청'), findsNothing);
    });

    testWidgets('자리가 찬 날은 마감으로 잠긴다', (tester) async {
      var called = false;
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [
            _entry(session: _session(participantCount: 8, capacity: 8)),
          ],
          now: _now,
          onToggleSession: (_, _) => called = true,
        ),
      );

      expect(find.text('마감'), findsOneWidget);
      await tester.tap(find.text('마감'));
      await tester.pumpAndSettle();
      // 잠긴 버튼은 확인 창도 띄우지 않는다.
      expect(find.text('이 일정으로 참여할까요?'), findsNothing);
      expect(called, isFalse);
    });

    testWidgets('자리가 찼어도 이미 신청했다면 뺄 수 있다', (tester) async {
      var called = false;
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [
            _entry(
              session: _session(
                participantCount: 8,
                capacity: 8,
                isJoined: true,
              ),
            ),
          ],
          now: _now,
          onToggleSession: (_, _) => called = true,
        ),
      );

      expect(find.text('마감'), findsNothing);
      await tester.tap(find.text('참여 중'));
      await tester.pumpAndSettle();

      expect(find.text('참여를 취소할까요?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '참여 취소'));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('첫 장에서도 좌우로 이웃 카드가 걸쳐 보인다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [
            _entry(id: 'a'),
            _entry(id: 'b'),
            _entry(id: 'c'),
          ],
          now: _now,
          onToggleSession: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller!.viewportFraction, lessThan(1.0));
      // 무한 순환이라 총 개수가 정해져 있지 않다.
      expect(pageView.childrenDelegate.estimatedChildCount, isNull);
    });

    testWidgets('끝까지 넘겨도 처음으로 이어진다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [
            _entry(id: 'a'),
            _entry(id: 'b'),
          ],
          now: _now,
          onToggleSession: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
      expect(find.text('카페 오리진'), findsWidgets);
    });

    testWidgets('한 장뿐이면 순환시키지 않는다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_entry()],
          now: _now,
          onToggleSession: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.childrenDelegate.estimatedChildCount, 1);
    });

    testWidgets('다크 모드에서도 오버플로 없이 그려진다', (tester) async {
      await tester.pumpScreen(
        MeetupCarousel(
          meetups: [_entry()],
          now: _now,
          onToggleSession: (_, _) {},
        ),
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
