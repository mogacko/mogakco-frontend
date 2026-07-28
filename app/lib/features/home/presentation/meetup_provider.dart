import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/current_chapter_provider.dart';
import '../data/mock_meetups.dart';
import '../domain/meetup.dart';

/// 모집 중인 모임 목록과 참여 상태.
///
/// 서버가 붙기 전이라 목업을 메모리에 두고 참여 토글만 반영한다.
class MeetupList extends Notifier<List<Meetup>> {
  @override
  List<Meetup> build() {
    // 인기순은 목록을 받아올 때 한 번만 정한다.
    // 볼 때마다 다시 정렬하면 참여를 누르는 순간 카드가 재배열돼
    // 보고 있던 자리를 잃는다. 서버가 붙어도 내려준 순서를 그대로 쓴다.
    final meetups = [...MockMeetups.all];
    meetups.sort((a, b) {
      // 신청할 수 없는 모임은 인기와 무관하게 뒤로 미룬다.
      if (a.isFull != b.isFull) return a.isFull ? 1 : -1;
      return b.fillRate.compareTo(a.fillRate);
    });
    return meetups;
  }

  /// 참여 신청과 취소를 오간다.
  ///
  /// 정원이 찬 모임은 새로 신청할 수 없지만, 이미 신청한 모임은 언제든 취소된다.
  void toggleJoin(String id) {
    state = [
      for (final meetup in state)
        if (meetup.id != id)
          meetup
        else if (meetup.isJoined)
          meetup.copyWith(
            isJoined: false,
            participantCount: meetup.participantCount - 1,
          )
        else if (!meetup.isFull)
          meetup.copyWith(
            isJoined: true,
            participantCount: meetup.participantCount + 1,
          )
        else
          meetup,
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
