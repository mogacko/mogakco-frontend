import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// 넓은 화면에서도 앱을 폰 폭으로 잡아 두는 틀.
///
/// 이 앱은 폰을 보고 만든다. 데스크톱 브라우저에서 열면 카드 하나가 화면
/// 전체로 늘어나 읽기 힘들어진다. 웹 전용 레이아웃을 따로 만드는 대신
/// 폭만 묶어 두고, 남는 자리는 배경으로 채운다.
///
/// 폰에서는 화면이 [maxWidth]보다 좁아 아무 일도 하지 않는다.
class MobileFrame extends StatelessWidget {
  const MobileFrame({super.key, required this.child, this.maxWidth = 460});

  final Widget child;

  /// 앱이 차지할 최대 폭. 큰 폰 기준으로 잡았다.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = math.min(media.size.width, maxWidth);

    // 화면이 좁으면 손댈 게 없다.
    if (width >= media.size.width) return child;

    final colors = context.colors;

    return ColoredBox(
      // 앱 바깥이라는 게 드러나야 폭이 좁은 게 의도로 읽힌다.
      color: colors.surfaceAlt,
      child: Center(
        child: SizedBox(
          width: width,
          child: ColoredBox(
            color: colors.background,
            // 화면 크기를 좁힌 폭으로 알려줘야 이 안에서 재는 값들이 어긋나지
            // 않는다. 그대로 두면 브라우저 폭을 기준으로 계산한다.
            child: MediaQuery(
              data: media.copyWith(size: Size(width, media.size.height)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
