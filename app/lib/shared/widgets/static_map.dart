import 'dart:math';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 움직이지 않는 지도 한 장.
///
/// 지도 SDK 를 넣지 않는다. flutter_map 은 의존성 29개를 끌고 오고, 카카오·
/// 네이버 지도는 API 키가 필요하다. 상세 화면에서 필요한 건 '어느 동네냐'를
/// 한눈에 보여주는 것이고, 실제 길찾기는 [onOpen] 으로 지도 앱에 넘긴다.
///
/// OSM 타일을 좌표에 맞춰 직접 깐다. 웹에서도 받아지고(CORS 허용) 키가 없다.
/// 다만 tile.openstreetmap.org 는 커뮤니티 서버라 사용량이 늘면 자체 타일
/// 서버나 상용 제공자로 옮겨야 한다.
class StaticMap extends StatelessWidget {
  const StaticMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 160,
    this.zoom = 16,
    this.onOpen,
  });

  final double latitude;
  final double longitude;
  final double height;

  /// 16이면 폭 340 기준 약 900m 가 담긴다. 동네를 알아볼 만한 크기다.
  final int zoom;

  /// 눌렀을 때 지도 앱으로 넘기는 동작. 없으면 그림만 놓인다.
  final VoidCallback? onOpen;

  static const _tileSize = 256.0;

  /// 슬리피 맵 좌표계. 경도는 그대로 비례하고 위도는 메르카토르로 눕힌다.
  double get _worldX => (longitude + 180) / 360 * (1 << zoom) * _tileSize;

  double get _worldY {
    final rad = latitude * pi / 180;
    // dart:math 에 asinh 가 없어 정의식으로 푼다.
    final y = (1 - log(tan(rad) + 1 / cos(rad)) / pi) / 2;
    return y * (1 << zoom) * _tileSize;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            // 찍을 자리가 가운데 오도록 왼쪽 위 월드 좌표를 잡는다.
            final left = _worldX - width / 2;
            final top = _worldY - height / 2;

            final firstCol = (left / _tileSize).floor();
            final firstRow = (top / _tileSize).floor();
            final cols = (width / _tileSize).ceil() + 1;
            final rows = (height / _tileSize).ceil() + 1;
            final maxTile = 1 << zoom;

            return Stack(
              children: [
                // 타일이 아직 안 왔을 때 비치는 바탕
                Positioned.fill(child: ColoredBox(color: colors.surfaceAlt)),
                for (var dy = 0; dy < rows; dy++)
                  for (var dx = 0; dx < cols; dx++)
                    _Tile(
                      zoom: zoom,
                      x: firstCol + dx,
                      y: firstRow + dy,
                      maxTile: maxTile,
                      size: _tileSize,
                      dx: (firstCol + dx) * _tileSize - left,
                      dy: (firstRow + dy) * _tileSize - top,
                    ),
                // 찍은 자리. 그림자를 얇게 둬서 타일 위에서 떠 보인다.
                Center(
                  child: Icon(
                    CupertinoIcons.location_solid,
                    size: 30,
                    color: colors.primary,
                    shadows: const [
                      Shadow(color: Color(0x40000000), blurRadius: 4),
                    ],
                  ),
                ),
                // OSM 타일을 쓰면 출처를 적어야 한다.
                Positioned(
                  right: 4,
                  bottom: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xB3FFFFFF),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      child: Text(
                        '© OpenStreetMap',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 9,
                          height: 1.2,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ),
                  ),
                ),
                if (onOpen != null)
                  Positioned.fill(
                    child: Semantics(
                      button: true,
                      label: '지도 앱에서 보기',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(onTap: onOpen),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.zoom,
    required this.x,
    required this.y,
    required this.maxTile,
    required this.size,
    required this.dx,
    required this.dy,
  });

  final int zoom;
  final int x;
  final int y;
  final int maxTile;
  final double size;
  final double dx;
  final double dy;

  @override
  Widget build(BuildContext context) {
    // 세로는 감싸지 않는다. 극지방 밖으로 나간 칸은 그냥 비운다.
    if (y < 0 || y >= maxTile) return const SizedBox.shrink();
    // 가로는 날짜변경선에서 이어진다.
    final wrappedX = x % maxTile;

    return Positioned(
      left: dx,
      top: dy,
      width: size,
      height: size,
      child: Image.network(
        'https://tile.openstreetmap.org/$zoom/$wrappedX/$y.png',
        fit: BoxFit.cover,
        // 한 칸을 못 받아도 지도 전체가 깨지지 않게 그 칸만 비운다.
        errorBuilder: (context, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

/// 지도 앱으로 넘기는 주소.
///
/// 카카오맵 링크를 쓴다. 앱이 깔려 있으면 앱이 열리고 없으면 웹 지도가 열린다.
/// 한국에서 길찾기는 대개 카카오나 네이버로 하므로 구글 지도로 보내면 한 번 더
/// 옮겨 타야 한다.
Uri kakaoMapLink({
  required String name,
  required double latitude,
  required double longitude,
}) {
  return Uri.parse(
    'https://map.kakao.com/link/map/'
    '${Uri.encodeComponent(name)},$latitude,$longitude',
  );
}

/// 지도 블록 아래에 두는 열기 버튼
class OpenInMapButton extends StatelessWidget {
  const OpenInMapButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.arrow_up_right_square,
                  size: AppSize.iconSm,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '지도 앱에서 열기',
                  style: context.texts.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
