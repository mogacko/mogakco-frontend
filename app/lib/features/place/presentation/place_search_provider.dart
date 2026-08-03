import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_delay.dart';
import '../../../shared/domain/chapter.dart';
import '../data/mock_places.dart';
import '../domain/place.dart';

/// 검색 한 번을 가리키는 키.
typedef PlaceQuery = ({String keyword, Chapter chapter});

/// 검색어 몇 글자부터 찾아볼지.
///
/// 한 글자로는 거의 모든 곳이 걸려서 목록이 아니라 벽이 된다. 두 글자면
/// '모모', '역삼'처럼 실제로 사람이 치는 최소 단위가 들어온다.
const placeSearchMinLength = 2;

/// 장소 검색.
///
/// 실제로는 네이버 지역검색(openapi.naver.com/v1/search/local)을 쓴다. 다만
/// 앱에서 직접 부를 수 없다 — 클라이언트 키가 필요하고 CORS 로도 막혀 있어서
/// 서버가 프록시해야 한다. 이 프로바이더 몸통이 그 호출로 바뀔 자리다.
///
/// autoDispose 로 두는 이유는 검색어마다 결과가 하나씩 쌓이는데, 장소를 고르고
/// 나면 그중 어느 것도 다시 쓰지 않기 때문이다.
final placeSearchProvider = FutureProvider.autoDispose
    .family<List<Place>, PlaceQuery>((ref, query) async {
      final keyword = query.keyword.trim();
      if (keyword.length < placeSearchMinLength) return const [];

      await Future<void>.delayed(mockNetworkDelay);
      return MockPlaces.search(keyword, chapter: query.chapter);
    });
