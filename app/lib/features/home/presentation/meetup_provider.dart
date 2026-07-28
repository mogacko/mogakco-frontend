import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/current_chapter_provider.dart';
import '../data/mock_meetups.dart';
import '../domain/meetup.dart';

/// 기준 시각.
///
/// '이번 주'와 '오늘/내일'을 재는 잣대다. 테스트에서 갈아끼울 수 있도록
/// DateTime.now() 를 화면 곳곳에 흩지 않고 여기 한 곳에 둔다.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

/// 모임 목록과 참여 상태.
///
/// 서버가 붙기 전이라 목업을 메모리에 두고 참여 토글만 반영한다.
class MeetupList extends Notifier<List<Meetup>> {
  @override
  List<Meetup> build() {
    final now = ref.watch(nowProvider);

    // 이번 주에 열리는 모임만, 가까운 날부터.
    //
    // 순서는 여기서 한 번만 정한다. 볼 때마다 다시 정렬하면 참여를 누르는
    // 순간 카드가 재배열돼 보고 있던 자리를 잃는다.
    final meetups =
        MockMeetups.from(now).where((meetup) => meetup.isThisWeek(now)).toList()
          ..sort((a, b) => a.firstStartsAt.compareTo(b.firstStartsAt));

    return meetups;
  }

  /// 특정 날의 참여 신청과 취소를 오간다.
  void toggleSession(String meetupId, String sessionId) {
    state = [
      for (final meetup in state)
        if (meetup.id != meetupId) meetup else meetup.toggleSession(sessionId),
    ];
  }
}

final meetupListProvider = NotifierProvider<MeetupList, List<Meetup>>(
  MeetupList.new,
);

/// 지금 보고 있는 지역의 모임만 추린다. 순서는 [MeetupList]가 정한 대로 둔다.
final visibleMeetupsProvider = Provider<List<Meetup>>((ref) {
  final chapter = ref.watch(currentChapterProvider);
  return ref
      .watch(meetupListProvider)
      .where((meetup) => meetup.chapter == chapter)
      .toList();
});

/// 모임과 그 중 화면에 세울 하루.
typedef MeetupOnDay = ({Meetup meetup, MeetupSession session});

/// 홈 맨 위에 세울 하루치 모임들.
///
/// 오늘 열리는 모임이 있으면 그것만 보여준다. 갈지 말지를 오늘 하루로 좁혀야
/// 결정이 단순해지고, 참여도 그 하루에만 걸린다.
///
/// 오늘 모임이 없는 날이 더 흔하다. 그때 자리를 비워두는 대신 가장 가까운
/// 날을 대신 세운다. 무엇을 세웠는지는 [heroIsTodayProvider]가 알려준다.
final heroMeetupsProvider = Provider<List<MeetupOnDay>>((ref) {
  final now = ref.watch(nowProvider);
  final meetups = ref.watch(visibleMeetupsProvider);

  final today = <MeetupOnDay>[];
  final upcoming = <MeetupOnDay>[];

  for (final meetup in meetups) {
    final session = meetup.sessionToday(now);
    if (session != null) {
      today.add((meetup: meetup, session: session));
      continue;
    }
    final next = meetup.nextSession(now);
    if (next != null) upcoming.add((meetup: meetup, session: next));
  }

  if (today.isNotEmpty) return today;

  upcoming.sort((a, b) => a.session.startsAt.compareTo(b.session.startsAt));
  return upcoming;
});

/// 홈 맨 위가 오늘 모임인지. 아니면 다가오는 모임을 대신 세운 것이다.
final heroIsTodayProvider = Provider<bool>((ref) {
  final now = ref.watch(nowProvider);
  return ref
      .watch(visibleMeetupsProvider)
      .any((meetup) => meetup.sessionToday(now) != null);
});
