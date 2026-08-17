import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_delay.dart';
import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/providers/now_provider.dart';
import '../../auth/presentation/session_provider.dart';
import '../../member/presentation/member_provider.dart';
import '../../profile/data/mock_profile.dart';
import '../data/mock_meetups.dart';
import '../../../shared/data/paging_notifier.dart';
import '../../../shared/widgets/paged.dart';
import '../../safety/domain/report.dart';
import '../../safety/presentation/safety_provider.dart';
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
    final me = _me;
    state = [
      for (final meetup in state)
        if (meetup.id != meetupId)
          meetup
        else
          meetup.toggleSession(sessionId, me),
    ];
  }

  /// 참여자 목록에 넣고 뺄 내 이름.
  ///
  /// 세션에서 읽는다. 프로필에서 닉네임을 고치면 세션도 함께 가므로 둘이
  /// 어긋나지 않는다.
  String get _me => ref.read(sessionProvider)?.nickname ?? MockProfile.nickname;

  /// 새 모각코를 연다.
  ///
  /// 목록 맨 앞이 아니라 날짜순 제자리에 꽂는다. 방금 만든 것이 위에 있으면
  /// 기분은 좋지만, 이 목록은 '가까운 날부터'가 규칙이라 한 줄만 어긋나도
  /// 나머지 순서를 못 믿게 된다.
  /// 모임장 이름을 바꾼다. 프로필에서 닉네임을 고칠 때 따라온다.
  void renameHost(String from, String to) {
    state = [
      for (final meetup in state)
        if (meetup.host != from) meetup else meetup.withHost(to),
    ];
  }

  /// 사유를 달아 모임을 접는다. 목록에서 지우지는 않는다.
  ///
  /// 오기로 했던 사람은 그 자리가 어떻게 됐는지 확인하러 오는데, 통째로
  /// 사라지면 자기가 잘못 본 건지 알 수 없다.
  void cancel(String meetupId, Cancellation cancellation) {
    state = [
      for (final meetup in state)
        if (meetup.id != meetupId) meetup else meetup.cancel(cancellation),
    ];
  }

  /// 모임장이 한 사람을 내보낸다.
  void kick(String meetupId, String memberId) {
    state = [
      for (final meetup in state)
        if (meetup.id != meetupId) meetup else meetup.kick(memberId),
    ];
  }

  void add(Meetup meetup) {
    state = [...state, meetup]
      ..sort((a, b) => a.firstStartsAt.compareTo(b.firstStartsAt));
  }

  /// 고친 모임으로 갈아 끼운다.
  ///
  /// 날짜가 바뀌면 목록에서 설 자리도 바뀌므로 다시 세운다. 이 목록은
  /// '가까운 날부터'가 규칙이라 한 줄만 어긋나도 나머지 순서를 못 믿게 된다.
  void replace(Meetup meetup) {
    state = [
      for (final it in state)
        if (it.id != meetup.id) it else meetup,
    ]..sort((a, b) => a.firstStartsAt.compareTo(b.firstStartsAt));
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
              restored = restored.toggleSession(session.id, _me);
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
///
/// 차단한 사람이 연 모임과 내가 신고한 모임은 여기서 빠진다.
final visibleMeetupsProvider = Provider<List<Meetup>>((ref) {
  final chapter = ref.watch(currentChapterProvider);
  final blocked = ref.watch(blockedProvider);
  final reported = ref.watch(reportedKeysProvider);

  return ref
      .watch(meetupListProvider)
      .where((meetup) => meetup.chapter == chapter)
      .where((meetup) => !blocked.contains(meetup.host))
      .where(
        (meetup) =>
            !reported.contains('${ReportTarget.meetup.name}:${meetup.id}'),
      )
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
    // 접힌 모임은 홈에 세우지 않는다. 홈 맨 위는 '오늘 갈 곳'을 묻는 자리라
    // 안 열리는 자리가 답이 될 수 없다.
    if (meetup.isCancelled) continue;
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
  hosting('내가 연'),
  recurring('정기');

  const MeetupFilter(this.label);

  final String label;

  /// [me] 는 지금 로그인한 사람. '내가 연' 에서만 쓴다.
  ///
  /// 목록 순서는 건드리지 않는다. 내가 연 모임을 맨 위로 올리면 '가까운
  /// 날부터'가 깨져서 나머지 순서를 못 믿게 된다. 대신 걸러서 모아 본다.
  bool matches(Meetup meetup, String me) => switch (this) {
    MeetupFilter.all => true,
    MeetupFilter.joined => meetup.isJoinedAny,
    MeetupFilter.hosting => meetup.host == me,
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
  final me = ref.watch(myIdProvider);
  return ref
      .watch(visibleMeetupsProvider)
      .where((meetup) => filter.matches(meetup, me))
      .toList();
});

/// Meetup 목록을 나눠 받는다.
class MeetupPaging extends Notifier<PageState> with PagingNotifier {
  @override
  int get total => ref.read(filteredMeetupsProvider).length;

  @override
  PageState build() {
    // 필터를 바꾸면 처음부터 다시 받는다. 스무 개까지 보다 옮겼는데 스무
    // 개가 차 있으면 아래가 텅 빈 것처럼 보인다.
    ref.watch(meetupFilterProvider);
    return begin();
  }
}

final meetupPagingProvider = NotifierProvider<MeetupPaging, PageState>(MeetupPaging.new);

/// 화면에 실제로 뿌릴 것.
final pagedMeetupsProvider = Provider<Paged<Meetup>>((ref) {
  final all = ref.watch(filteredMeetupsProvider);
  final page = ref.watch(meetupPagingProvider);

  return Paged(
    items: all.take(page.loaded).toList(),
    hasMore: page.loaded < all.length,
    isLoading: page.isLoading,
    isLoadingMore: page.isLoadingMore,
    error: page.error,
  );
});

/// 기준별 모임 개수. 필터 알약에 붙인다.
final meetupCountsProvider = Provider<Map<MeetupFilter, int>>((ref) {
  final meetups = ref.watch(visibleMeetupsProvider);
  final me = ref.watch(myIdProvider);
  return {
    for (final filter in MeetupFilter.values)
      filter: meetups.where((meetup) => filter.matches(meetup, me)).length,
  };
});
