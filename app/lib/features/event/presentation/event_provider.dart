import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/providers/now_provider.dart';
import '../data/mock_events.dart';
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
}

final eventListProvider = NotifierProvider<EventList, List<Event>>(
  EventList.new,
);

/// 지금 보고 있는 지역의 행사. 순서는 [EventList] 가 정한 대로 둔다.
final chapterEventsProvider = Provider<List<Event>>((ref) {
  final chapter = ref.watch(currentChapterProvider);
  return ref
      .watch(eventListProvider)
      .where((event) => event.chapter == chapter)
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

/// 종류별 행사 개수. 필터 알약에 붙인다.
final eventCountsProvider = Provider<Map<EventKind, int>>((ref) {
  final counts = <EventKind, int>{};
  for (final event in ref.watch(chapterEventsProvider)) {
    counts[event.kind] = (counts[event.kind] ?? 0) + 1;
  }
  return counts;
});
