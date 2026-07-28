import '../../../shared/domain/chapter.dart';
import '../domain/meetup.dart';

/// 화면을 채우기 위한 임시 데이터.
///
/// 서버 연동 전까지만 쓴다. 실제 데이터가 붙으면 이 파일은 지운다.
abstract final class MockMeetups {
  static const all = <Meetup>[
    Meetup(
      id: 'seoul-1',
      chapter: Chapter.seoul,
      placeName: '카페 그리다',
      address: '서울특별시 강남구 역삼동',
      participantCount: 6,
      capacity: 8,
    ),
    Meetup(
      id: 'seoul-2',
      chapter: Chapter.seoul,
      placeName: '스터디홀 합정',
      address: '서울특별시 마포구 합정동',
      participantCount: 4,
      capacity: 10,
      isJoined: true,
    ),
    Meetup(
      id: 'seoul-3',
      chapter: Chapter.seoul,
      placeName: '언플러그드 성수',
      address: '서울특별시 성동구 성수동',
      participantCount: 9,
      capacity: 9,
    ),
    Meetup(
      id: 'busan-1',
      chapter: Chapter.busan,
      placeName: '모모스커피 온천장',
      address: '부산광역시 동래구 온천동',
      participantCount: 5,
      capacity: 8,
    ),
    Meetup(
      id: 'busan-2',
      chapter: Chapter.busan,
      placeName: '웨이브온 커피',
      address: '부산광역시 기장군 일광면',
      participantCount: 3,
      capacity: 6,
    ),
    Meetup(
      id: 'busan-3',
      chapter: Chapter.busan,
      placeName: '카페 오리진',
      address: '부산광역시 해운대구 우동',
      participantCount: 7,
      capacity: 12,
      isJoined: true,
    ),
    Meetup(
      id: 'busan-4',
      chapter: Chapter.busan,
      placeName: '초량1941',
      address: '부산광역시 동구 초량동',
      participantCount: 2,
      capacity: 6,
    ),
  ];
}
