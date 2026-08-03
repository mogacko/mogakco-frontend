import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_delay.dart';
import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/providers/now_provider.dart';
import '../data/mock_meetups.dart';
import '../domain/meetup.dart';

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

  /// 새 모각코를 연다.
  ///
  /// 목록 맨 앞이 아니라 날짜순 제자리에 꽂는다. 방금 만든 것이 위에 있으면
  /// 기분은 좋지만, 이 목록은 '가까운 날부터'가 규칙이라 한 줄만 어긋나도
  /// 나머지 순서를 못 믿게 된다.
  void add(Meetup meetup) {
    state = [...state, meetup]
      ..sort((a, b) => a.firstStartsAt.compareTo(b.firstStartsAt));
  }

  /// 당겨서 새로고침.
  ///
  /// 서버가 붙으면 여기서 다시 받아온다. 그때는 내가 신청한 날도 응답에
  /// 실려 오므로 아래 옮겨 담기는 지운다.
  Future<void> refresh() async {
    // 목업에 없던 것 = 여기서 내가 연 것. 서버가 붙으면 응답에 실려 오므로
    // 이 옮겨 담기는 지운다.
    final mine = state.where((meetup) => meetup.id.startsWith(localPrefix));
    final joined = {
      for (final meetup in state)
        for (final session in meetup.sessions)
          if (session.isJoined) session.id,
    };

    await Future<void>.delayed(mockNetworkDelay);

    final now = ref.read(nowProvider);

    state =
        MockMeetups.from(now).where((meetup) => meetup.isThisWeek(now)).map((
          meetup,
        ) {
          var restored = meetup;
          for (final session in meetup.sessions) {
            if (session.isJoined != joined.contains(session.id)) {
              restored = restored.toggleSession(session.id);
            }
          }
          return restored;
        }).toList()
          ..addAll(mine)
          ..sort((a, b) => a.firstStartsAt.compareTo(b.firstStartsAt));
  }

  /// 서버가 아직 id 를 주지 못하는 동안 쓰는 앞머리.
  static const localPrefix = 'local-';
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

/// 모임 탭에서 목록을 좁히는 기준.
///
/// '내가 신청한 것만'과 '매주 열리는 것만'은 찾는 이유가 서로 다르다. 앞은
/// 이번 주에 어디를 가기로 했는지 확인하러 오고, 뒤는 꾸준히 나갈 자리를
/// 고르러 온다.
enum MeetupFilter {
  all('전체'),
  joined('참여 중'),
  recurring('정기');

  const MeetupFilter(this.label);

  final String label;

  bool matches(Meetup meetup) => switch (this) {
    MeetupFilter.all => true,
    MeetupFilter.joined => meetup.isJoinedAny,
    MeetupFilter.recurring => meetup.isRecurring,
  };
}

class MeetupFilterSelection extends Notifier<MeetupFilter> {
  @override
  MeetupFilter build() => MeetupFilter.all;

  void select(MeetupFilter filter) => state = filter;
}

final meetupFilterProvider =
    NotifierProvider<MeetupFilterSelection, MeetupFilter>(
      MeetupFilterSelection.new,
    );

/// 모임 탭에 뿌릴 모임
final filteredMeetupsProvider = Provider<List<Meetup>>((ref) {
  final filter = ref.watch(meetupFilterProvider);
  return ref
      .watch(visibleMeetupsProvider)
      .where(filter.matches)
      .toList();
});

/// 기준별 모임 개수. 필터 알약에 붙인다.
final meetupCountsProvider = Provider<Map<MeetupFilter, int>>((ref) {
  final meetups = ref.watch(visibleMeetupsProvider);
  return {
    for (final filter in MeetupFilter.values)
      filter: meetups.where(filter.matches).length,
  };
});
