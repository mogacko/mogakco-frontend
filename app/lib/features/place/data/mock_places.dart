import '../../../shared/domain/chapter.dart';
import '../domain/place.dart';

/// 검색에 걸릴 장소 목록.
///
/// 서버가 붙으면 통째로 지운다. 진짜 검색은 네이버 지역검색이 하고, 여기 있는
/// 건 그 응답을 흉내 낸 것뿐이다.
abstract final class MockPlaces {
  static const _busan = <Place>[
    Place(
      id: 'busan-momos-oncheon',
      name: '모모스커피 온천장',
      address: '부산광역시 동래구 금강공원로 73번길 1',
      category: '카페',
      latitude: 35.2224,
      longitude: 129.0866,
    ),
    Place(
      id: 'busan-momos-yeongdo',
      name: '모모스커피 영도',
      address: '부산광역시 영도구 태종로 6',
      category: '카페',
      latitude: 35.0949,
      longitude: 129.0416,
    ),
    Place(
      id: 'busan-waveon',
      name: '웨이브온 커피',
      address: '부산광역시 기장군 일광읍 기장해안로 590',
      category: '카페',
      latitude: 35.2635,
      longitude: 129.236,
    ),
    Place(
      id: 'busan-origin',
      name: '카페 오리진 해운대',
      address: '부산광역시 해운대구 구남로 22',
      category: '카페',
      latitude: 35.1631,
      longitude: 129.1636,
    ),
    Place(
      id: 'busan-choryang1941',
      name: '초량1941',
      address: '부산광역시 동구 망양로533번길 5',
      category: '카페',
      latitude: 35.116,
      longitude: 129.04,
    ),
    Place(
      id: 'busan-studyhall-seomyeon',
      name: '토즈 스터디센터 서면점',
      address: '부산광역시 부산진구 중앙대로 692',
      category: '스터디카페',
      latitude: 35.1577,
      longitude: 129.0594,
    ),
    Place(
      id: 'busan-centum-library',
      name: '부산광역시립시민도서관',
      address: '부산광역시 부산진구 월드컵대로 462',
      category: '도서관',
      latitude: 35.1817,
      longitude: 129.0533,
    ),
    Place(
      id: 'busan-cafe-hyundai',
      name: '카페 현대 광안리',
      address: '부산광역시 수영구 광안해변로 219',
      category: '카페',
      latitude: 35.1532,
      longitude: 129.1188,
    ),
  ];

  static const _seoul = <Place>[
    Place(
      id: 'seoul-grida',
      name: '카페 그리다 역삼',
      address: '서울특별시 강남구 테헤란로 132',
      category: '카페',
      latitude: 37.5006,
      longitude: 127.0364,
    ),
    Place(
      id: 'seoul-studyhall-hapjeong',
      name: '스터디홀 합정',
      address: '서울특별시 마포구 양화로 45',
      category: '스터디카페',
      latitude: 37.5495,
      longitude: 126.9138,
    ),
    Place(
      id: 'seoul-unplugged',
      name: '언플러그드 성수',
      address: '서울특별시 성동구 연무장길 33',
      category: '카페',
      latitude: 37.5445,
      longitude: 127.0557,
    ),
    Place(
      id: 'seoul-anthracite',
      name: '앤트러사이트 한남',
      address: '서울특별시 용산구 이태원로 240',
      category: '카페',
      latitude: 37.5372,
      longitude: 127.0021,
    ),
    Place(
      id: 'seoul-fritz',
      name: '프릳츠 도화점',
      address: '서울특별시 마포구 새창로2길 17',
      category: '카페',
      latitude: 37.5407,
      longitude: 126.9503,
    ),
    Place(
      id: 'seoul-library-jongno',
      name: '서울도서관',
      address: '서울특별시 중구 세종대로 110',
      category: '도서관',
      latitude: 37.5663,
      longitude: 126.9779,
    ),
    Place(
      id: 'seoul-toz-gangnam',
      name: '토즈 강남토즈타워점',
      address: '서울특별시 강남구 강남대로 402',
      category: '스터디카페',
      latitude: 37.4979,
      longitude: 127.0276,
    ),
  ];

  /// 지역 안에서 [keyword]가 이름이나 주소에 든 곳.
  ///
  /// 실제 검색은 좌표를 기준으로 가까운 순을 내주지만, 목업은 지역으로만
  /// 가른다. 검색 결과가 서울에 있는데 부산 모임으로 잡히면 안 되기 때문이다.
  static List<Place> search(String keyword, {required Chapter chapter}) {
    final query = keyword.trim();
    if (query.isEmpty) return const [];

    return _of(chapter)
        .where(
          (place) =>
              place.name.contains(query) || place.address.contains(query),
        )
        .toList();
  }

  static List<Place> _of(Chapter chapter) => switch (chapter) {
    Chapter.seoul => _seoul,
    Chapter.busan => _busan,
    // 아직 열리지 않은 지역. 열리면 그 지역 목록이 서버에서 온다.
    _ => const [],
  };
}
