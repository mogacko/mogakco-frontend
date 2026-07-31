import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/shared/widgets/static_map.dart';

import '../helpers/pump_app.dart';

void main() {
  group('StaticMap', () {
    /// 서울시청. 슬리피 맵 좌표가 널리 알려진 지점이라 계산을 견주기 좋다.
    const lat = 37.5665;
    const lon = 126.9780;

    testWidgets('찍은 자리를 담은 타일을 불러온다', (tester) async {
      await tester.pumpScreen(
        const Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: StaticMap(latitude: lat, longitude: lon),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final urls = find
          .byType(Image)
          .evaluate()
          .map((e) => ((e.widget as Image).image as NetworkImage).url)
          .toList();

      // zoom 16(65536칸)에서 서울시청의 분수 좌표는 x=55883.639, y=25378.966.
      //   x = (126.978 + 180) / 360 * 65536
      //   y = (1 - ln(tan φ + sec φ) / π) / 2 * 65536
      // 따라서 그 지점이 들어 있는 칸은 55883/25378 이다.
      expect(
        urls,
        contains('https://tile.openstreetmap.org/16/55883/25378.png'),
      );
    });

    testWidgets('가운데를 채우려면 이웃 타일까지 깐다', (tester) async {
      await tester.pumpScreen(
        const Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: StaticMap(latitude: lat, longitude: lon),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 340x160 상자를 256 짜리 타일로 덮으려면 한 칸으로는 모자란다.
      expect(find.byType(Image), findsAtLeast(2));
    });

    testWidgets('출처를 적는다', (tester) async {
      await tester.pumpScreen(
        const Scaffold(
          body: StaticMap(latitude: lat, longitude: lon),
        ),
      );
      await tester.pumpAndSettle();

      // OSM 타일을 쓰면 표기 의무가 있다. 지우면 이 테스트가 잡는다.
      expect(find.text('© OpenStreetMap'), findsOneWidget);
    });
  });

  group('naverMapLink', () {
    test('좌표를 질의로 싣는다', () {
      final link = naverMapLink(
        name: '카페 오리진',
        latitude: 35.1631,
        longitude: 129.1636,
      );

      expect(link.host, 'map.naver.com');
      expect(link.queryParameters['lat'], '35.1631');
      expect(link.queryParameters['lng'], '129.1636');
      expect(link.queryParameters['title'], '카페 오리진');
    });

    test('이름에 쉼표가 섞여도 좌표와 갈리지 않는다', () {
      final link = naverMapLink(
        name: '카페 오리진, 2층',
        latitude: 35.1631,
        longitude: 129.1636,
      );

      // 좌표를 경로에 쉼표로 이어 붙이던 시절에는 이름 속 쉼표가 구분자로
      // 읽혀 위치가 밀렸다. 질의로 실으면 그 일이 생기지 않는다.
      expect(link.queryParameters['title'], '카페 오리진, 2층');
      expect(link.queryParameters['lat'], '35.1631');
    });
  });
}
