import '../../../shared/domain/chapter.dart';
import '../domain/meetup.dart';

/// 화면을 채우기 위한 임시 데이터.
///
/// 서버 연동 전까지만 쓴다. 실제 데이터가 붙으면 이 파일은 지운다.
///
/// 좌표는 실제 장소 근처로 잡은 값이다. 동네까지는 맞지만 건물 단위로
/// 정확하지는 않다. 실제 값은 모임을 만들 때 지오코딩으로 얻는다.
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
        host: '재현',
        chapter: Chapter.busan,
        placeName: '모모스커피 온천장',
        address: '부산광역시 동래구 온천동',
        isRecurring: true,
        description:
            '매주 토·일 오전에 모여 각자 할 일을 합니다. 조용히 앉아 있다가 점심만 같이 먹고 헤어져요. '
            '처음 오시는 분은 입구 쪽 긴 테이블 보고 오시면 됩니다.',
        latitude: 35.2224,
        longitude: 129.0866,
        sessions: [
          MeetupSession(
            id: 'busan-1-today',
            startsAt: day(0, 10),
            participants: ['재현', '민서', '지훈', '서연', '태오'],
            capacity: 8,
          ),
          MeetupSession(
            id: 'busan-1-sun',
            startsAt: day(2, 13),
            participants: ['재현', '나윤', '하람'],
            capacity: 8,
          ),
        ],
      ),
      Meetup(
        id: 'busan-2',
        host: '수민',
        chapter: Chapter.busan,
        placeName: '웨이브온 커피',
        address: '부산광역시 기장군 일광면',
        latitude: 35.2635,
        longitude: 129.236,
        sessions: [
          MeetupSession(
            id: 'busan-2-today',
            startsAt: day(0, 14),
            participants: ['수민', '도윤', '민서', '준서', '나윤', '하람'],
            capacity: 6,
          ),
        ],
      ),
      Meetup(
        id: 'busan-3',
        host: 'evan',
        chapter: Chapter.busan,
        placeName: '카페 오리진',
        address: '부산광역시 해운대구 우동',
        isRecurring: true,
        description:
            '해운대 쪽에서 저녁에 모입니다. 늦게 오셔도 되고 중간에 가셔도 됩니다. '
            '콘센트 자리가 넉넉해서 노트북 오래 쓰기 좋아요.',
        latitude: 35.1631,
        longitude: 129.1636,
        sessions: [
          MeetupSession(
            id: 'busan-3-fri',
            startsAt: day(0, 19),
            participants: ['evan', '재현', '수민', '서연', '태오', '준서', '지훈'],
            capacity: 12,
            isJoined: true,
          ),
          MeetupSession(
            id: 'busan-3-sat',
            startsAt: day(1, 19),
            participants: ['evan', '민서', '나윤', '하람'],
            capacity: 12,
          ),
        ],
      ),
      Meetup(
        id: 'busan-4',
        host: '도윤',
        chapter: Chapter.busan,
        placeName: '초량1941',
        address: '부산광역시 동구 초량동',
        latitude: 35.116,
        longitude: 129.04,
        // 접힌 자리도 하나 둔다. 목록에서 어떻게 보이는지가 화면을 짜는 데
        // 필요하고, 실제로도 흔한 상태다.
        cancellation: Cancellation(
          reason: CancelReason.place,
          at: now.subtract(const Duration(hours: 6)),
        ),
        sessions: [
          MeetupSession(
            id: 'busan-4-sun',
            startsAt: day(2, 11),
            participants: ['도윤', '지훈'],
            capacity: 6,
          ),
        ],
      ),
      Meetup(
        id: 'seoul-1',
        host: '하늘',
        chapter: Chapter.seoul,
        placeName: '카페 그리다',
        address: '서울특별시 강남구 역삼동',
        isRecurring: true,
        description: '강남에서 주말 오전에 모입니다. 조용한 편이고 대화는 쉬는 시간에만 해요.',
        latitude: 37.5006,
        longitude: 127.0364,
        sessions: [
          MeetupSession(
            id: 'seoul-1-sat',
            startsAt: day(1, 11),
            participants: ['하늘', '지우', '예린', '시우', '유진', '다인'],
            capacity: 8,
          ),
          MeetupSession(
            id: 'seoul-1-sun',
            startsAt: day(2, 11),
            participants: ['하늘', '민준', '건우', '예린', '시우'],
            capacity: 8,
          ),
        ],
      ),
      Meetup(
        id: 'seoul-2',
        host: '지우',
        chapter: Chapter.seoul,
        placeName: '스터디홀 합정',
        address: '서울특별시 마포구 합정동',
        latitude: 37.5495,
        longitude: 126.9138,
        sessions: [
          MeetupSession(
            id: 'seoul-2-sat',
            startsAt: day(2, 14),
            participants: ['evan', '지우', '유진', '건우'],
            capacity: 10,
            isJoined: true,
          ),
        ],
      ),
      Meetup(
        id: 'seoul-3',
        // 서울에도 내가 연 자리를 하나 둔다. 부산에만 있으면 서울로 가입한
        // 사람은 모임장 기능(접기·내보내기)을 볼 데가 없다.
        host: 'evan',
        chapter: Chapter.seoul,
        placeName: '언플러그드 성수',
        address: '서울특별시 성동구 성수동',
        latitude: 37.5445,
        longitude: 127.0557,
        sessions: [
          MeetupSession(
            id: 'seoul-3-sun',
            startsAt: day(3, 13),
            participants: ['evan', '하늘', '지우', '예린', '시우', '유진', '다인', '건우', '나윤'],
            capacity: 9,
          ),
        ],
      ),
    ];
  }
}
