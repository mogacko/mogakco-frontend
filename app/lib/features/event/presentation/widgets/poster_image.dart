import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/poster.dart';

/// 포스터 그림 한 장.
///
/// 올린 것과 서버가 준 것을 여기서 가른다. 세 화면(목록·다가오는 행사·상세)이
/// 각자 갈랐다면 한 곳만 고쳐도 나머지 둘이 어긋난다.
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    required this.poster,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  final Poster poster;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// 받아오는 동안과 못 받았을 때 세울 것. 없으면 옅은 면.
  ///
  /// 그림이 안 와도 자리는 그대로 둬야 한다. 빈 칸이 사라지면 옆 글자가 밀려서
  /// 목록 전체가 들썩인다.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final placeholder =
        this.placeholder ??
        SizedBox(
          width: width,
          height: height,
          child: ColoredBox(color: context.colors.surfaceAlt),
        );

    return switch (poster) {
      RemotePoster(:final url) => Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronous) {
          if (wasSynchronous || frame != null) return child;
          return placeholder;
        },
        errorBuilder: (context, _, _) => placeholder,
      ),
      // 기기에서 고른 그림은 받아올 것이 없어 곧바로 그려진다.
      LocalPoster(:final bytes) => Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, _, _) => placeholder,
      ),
    };
  }
}
