import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/poster.dart';
import 'poster_image.dart';

/// 행사 목록 오른쪽에 붙는 포스터.
///
/// 오른쪽인 이유는 이 목록이 글을 먼저 읽는 자리라서다. 왼쪽은 눈이 먼저
/// 닿는 자리라 거기에 그림을 두면 제목보다 그림이 앞선다. 포스터는 제목을
/// 읽고 나서 '아 이런 자리구나' 하고 거드는 몫이다.
///
/// 없는 행사가 흔하다. 지부가 매번 포스터를 만들지는 않는다. 그때는 이
/// 위젯을 아예 세우지 않고 글이 폭을 다 쓴다. 자리를 빈 상자로 남겨두면
/// 무언가 빠진 것처럼 보인다.
class EventPoster extends StatelessWidget {
  const EventPoster({
    super.key,
    required this.poster,
    this.size = regularSize,
  });

  /// 행사 탭 카드용
  static const regularSize = 64.0;

  /// 홈 타일용. 줄이 얕아 그만큼 줄인다.
  static const compactSize = 52.0;

  final Poster poster;
  final double size;

  @override
  Widget build(BuildContext context) {
    // 받아오는 동안과 못 받았을 때 자리를 지킨다. 크기가 바뀌면 목록이 출렁인다.
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: PosterImage(
        poster: poster,
        width: size,
        height: size,
        // 포스터는 대개 세로로 길다. 정사각으로 잘라 줄 높이를 지킨다.
        fit: BoxFit.cover,
        placeholder: placeholder,
      ),
    );
  }
}
