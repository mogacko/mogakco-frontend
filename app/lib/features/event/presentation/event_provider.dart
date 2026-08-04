import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_delay.dart';
import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/providers/now_provider.dart';
import '../data/mock_events.dart';
import '../../safety/domain/report.dart';
import '../../safety/presentation/safety_provider.dart';
import '../domain/event.dart';

/// 행사 목록과 신청 상태.
///
/// 서버가 붙기 전이라 목업을 메모리에 두고 신청만 반영한다.
class EventList extends Notifier<List<Event>> {
  @override
  List<Event> build() {
    final now = ref.watch(nowProvider);

    // 이미 시작한 행사는 뺀다. 신청할 수 없는 자리가 목록 앞을 차지하면
    // 정작 다가오는 행사가 아래로 밀린다.
    //
    // 순서는 여기서 한 번만 정한다. 볼 때마다 다시 정렬하면 신청을 누르는
    // 순간 카드가 자리를 옮긴다.
    return MockEvents.from(now)
        .where((event) => event.startsAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  /// 신청과 취소를 오간다.
  ///
  /// 마감된 행사는 새로 신청할 수 없다. 이미 신청했다면 언제든 뺄 수 있다.
  void toggleApply(String eventId) {
    final now = ref.read(nowProvider);

    state = [
      for (final event in state)
        if (event.id != eventId)
          event
        else if (event.isApplied)
          event.cancel()
        else if (!event.isClosed(now))
          event.apply()
        else
          event,
    ];
  }

  /// 당겨서 새로고침.
  ///
  /// 서버가 붙으면 여기서 다시 받아온다. 그때는 내가 신청한 행사도 응답에
  /// 실려 오므로 아래 옮겨 담기는 지운다.
  Future<void> refresh() async {
    final applied = {
      for (final event in state)
        if (event.isApplied) event.id,
    };

    await Future<void>.delayed(mockNetworkDelay);

    final now = ref.read(nowProvider);

    state =
        MockEvents.from(now)
            .where((event) => event.startsAt.isAfter(now))
            .map((event) {
              // 목업에도 미리 신청해 둔 행사가 있다. 한쪽으로만 맞추면
              // 취소한 뒤 새로고침했을 때 신청이 되살아난다.
              final mine = applied.contains(event.id);
              if (event.isApplied == mine) return event;
              return mine ? event.apply() : event.cancel();
            })
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }
}

final eventListProvider = NotifierProvider<EventList, List<Event>>(
  EventList.new,
);

/// 지금 보고 있는 지역의 행사. 순서는 [EventList] 가 정한 대로 둔다.
///
/// 내가 신고한 행사는 여기서 빠진다. 행사는 지부가 여는 것이라 차단으로
/// 걸러낼 사람이 없다.
final chapterEventsProvider = Provider<List<Event>>((ref) {
  final chapter = ref.watch(currentChapterProvider);
  final reported = ref.watch(reportedKeysProvider);

  return ref
      .watch(eventListProvider)
      .where((event) => event.chapter == chapter)
      .where(
        (event) => !reported.contains('${ReportTarget.event.name}:${event.id}'),
      )
      .toList();
});

/// 고른 종류. null 이면 전체.
class EventFilter extends Notifier<EventKind?> {
  @override
  EventKind? build() => null;

  void select(EventKind? kind) => state = kind;
}

final eventFilterProvider = NotifierProvider<EventFilter, EventKind?>(
  EventFilter.new,
);

/// 행사 탭에 뿌릴 행사
final visibleEventsProvider = Provider<List<Event>>((ref) {
  final kind = ref.watch(eventFilterProvider);
  final events = ref.watch(chapterEventsProvider);

  if (kind == null) return events;
  return events.where((event) => event.kind == kind).toList();
});

/// 홈에 세울 개수.
///
/// 홈은 훑는 자리지 고르는 자리가 아니다. 셋을 넘기면 목록이 되어 행사 탭과
/// 하는 일이 겹친다.
const _homeEventCount = 2;

/// 홈에 세울 다가오는 행사.
///
/// [chapterEventsProvider] 가 이미 시작한 행사를 빼고 가까운 순으로 세워 두므로
/// 앞에서 몇 개만 떼면 된다.
///
/// 마감됐거나 자리가 찬 행사도 빼지 않는다. 가장 가까운 행사가 목록에서
/// 사라지면 곧 무슨 일이 있는지를 알 수 없게 된다. 신청할 수 있는지는
/// 각 줄의 D-day 가 말해 준다.
final upcomingEventsProvider = Provider<List<Event>>((ref) {
  return ref.watch(chapterEventsProvider).take(_homeEventCount).toList();
});

/// 종류별 행사 개수. 필터 알약에 붙인다.
final eventCountsProvider = Provider<Map<EventKind, int>>((ref) {
  final counts = <EventKind, int>{};
  for (final event in ref.watch(chapterEventsProvider)) {
    counts[event.kind] = (counts[event.kind] ?? 0) + 1;
  }
  return counts;
});
