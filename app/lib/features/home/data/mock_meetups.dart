import '../../../shared/domain/chapter.dart';
import '../domain/meetup.dart';

/// 화면을 채우기 위한 임시 데이터.
///
/// 서버 연동 전까지만 쓴다. 실제 데이터가 붙으면 이 파일은 지운다.
abstract final class MockMeetups {
  /// [now]를 기준으로 이번 주 모임을 만든다.
  ///
  /// 고정 날짜를 박아두면 하루만 지나도 지난 모임이 되어 화면이 빈다.
  /// 대신 날짜만 오늘로부터 상대로 잡고 시각은 고정해서, 언제 실행해도
  /// 같은 화면이 나오게 한다.
  static List<Meetup> from(DateTime now) {
    DateTime day(int after, int hour) {
      final base = DateTime(now.year, now.month, now.day);
      return base.add(Duration(days: after)).copyWith(hour: hour);
    }

    return [
      Meetup(
        id: 'busan-1',
        chapter: Chapter.busan,
        placeName: '모모스커피 온천장',
        address: '부산광역시 동래구 온천동',
        isRecurring: true,
        sessions: [
          MeetupSession(
            id: 'busan-1-today',
            startsAt: day(0, 10),
            participantCount: 5,
            capacity: 8,
          ),
          MeetupSession(
            id: 'busan-1-sun',
            startsAt: day(2, 13),
            participantCount: 3,
            capacity: 8,
          ),
        ],
      ),
      Meetup(
        id: 'busan-2',
        chapter: Chapter.busan,
        placeName: '웨이브온 커피',
        address: '부산광역시 기장군 일광면',
        sessions: [
          MeetupSession(
            id: 'busan-2-today',
            startsAt: day(0, 14),
            participantCount: 6,
            capacity: 6,
          ),
        ],
      ),
      Meetup(
        id: 'busan-3',
        chapter: Chapter.busan,
        placeName: '카페 오리진',
        address: '부산광역시 해운대구 우동',
        isRecurring: true,
        sessions: [
          MeetupSession(
            id: 'busan-3-fri',
            startsAt: day(0, 19),
            participantCount: 7,
            capacity: 12,
            isJoined: true,
          ),
          MeetupSession(
            id: 'busan-3-sat',
            startsAt: day(1, 19),
            participantCount: 4,
            capacity: 12,
          ),
        ],
      ),
      Meetup(
        id: 'busan-4',
        chapter: Chapter.busan,
        placeName: '초량1941',
        address: '부산광역시 동구 초량동',
        sessions: [
          MeetupSession(
            id: 'busan-4-sun',
            startsAt: day(2, 11),
            participantCount: 2,
            capacity: 6,
          ),
        ],
      ),
      Meetup(
        id: 'seoul-1',
        chapter: Chapter.seoul,
        placeName: '카페 그리다',
        address: '서울특별시 강남구 역삼동',
        isRecurring: true,
        sessions: [
          MeetupSession(
            id: 'seoul-1-sat',
            startsAt: day(1, 11),
            participantCount: 6,
            capacity: 8,
          ),
          MeetupSession(
            id: 'seoul-1-sun',
            startsAt: day(2, 11),
            participantCount: 5,
            capacity: 8,
          ),
        ],
      ),
      Meetup(
        id: 'seoul-2',
        chapter: Chapter.seoul,
        placeName: '스터디홀 합정',
        address: '서울특별시 마포구 합정동',
        sessions: [
          MeetupSession(
            id: 'seoul-2-sat',
            startsAt: day(2, 14),
            participantCount: 4,
            capacity: 10,
            isJoined: true,
          ),
        ],
      ),
      Meetup(
        id: 'seoul-3',
        chapter: Chapter.seoul,
        placeName: '언플러그드 성수',
        address: '서울특별시 성동구 성수동',
        sessions: [
          MeetupSession(
            id: 'seoul-3-sun',
            startsAt: day(3, 13),
            participantCount: 9,
            capacity: 9,
          ),
        ],
      ),
    ];
  }
}
