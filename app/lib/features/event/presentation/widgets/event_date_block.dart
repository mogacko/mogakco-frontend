import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// 달력 한 칸처럼 세우는 날짜.
///
/// 행사는 '무엇을 하느냐'만큼 '언제 하느냐'로 고르게 된다. 날짜가 본문 속 한
/// 줄로 섞여 있으면 목록을 훑으며 비교할 수 없어서 왼쪽에 따로 세운다.
class EventDateBlock extends StatelessWidget {
  const EventDateBlock({super.key, required this.date, this.compact = false});

  /// 포스터가 이 자리를 대신하므로 크기를 못 박아 둔다.
  ///
  /// 내용에 맡기면 세로가 68 쯤 되는데, 포스터를 정사각으로 잡으면 이미지가
  /// 붙는 순간 줄 높이가 튄다. 둘이 같은 상자를 쓰게 해서 무엇이 오든
  /// 자리가 흔들리지 않게 한다.
  static const regularSize = Size(52, 68);
  static const compactSize = Size(44, 58);

  static Size sizeOf({required bool compact}) =>
      compact ? compactSize : regularSize;

  final DateTime date;

  /// 홈처럼 좁은 자리에 놓을 때. 폭과 글자를 한 단계 줄이고 면을 깔지 않는다.
  ///
  /// 행사 탭에서는 카드(surfaceAlt) 위에 놓여 밝은 면이 달력 칸처럼 보이지만,
  /// 홈에서는 페이지 배경 위에 바로 놓인다. 같은 면을 깔면 라이트에서는
  /// 흰 바탕에 흰 면이라 보이지 않고 다크에서만 상자가 떠서, 두 테마가
  /// 다르게 보인다. 홈에서는 아예 깔지 않아 양쪽을 맞춘다.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    // 토·일은 달력에서 하듯 색을 달리한다. 주말인지가 갈 수 있는지를 가른다.
    final isWeekend = date.weekday >= 6;

    final size = sizeOf(compact: compact);

    return Container(
      width: size.width,
      height: size.height,
      alignment: Alignment.center,
      decoration: compact
          ? null
          : BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
      // 글꼴을 키운 기기에서는 세 줄이 상자를 넘는다. 넘치게 두는 대신
      // 통째로 줄여 상자 안에 앉힌다.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${date.month}월',
              style: context.texts.labelSmall?.copyWith(
                color: colors.textTertiary,
                height: 1.1,
              ),
            ),
            Text(
              '${date.day}',
              style: compact
                  ? context.texts.titleLarge?.copyWith(height: 1.2)
                  : context.texts.headlineMedium?.copyWith(height: 1.2),
            ),
            Text(
              weekdays[date.weekday - 1],
              style: context.texts.labelSmall?.copyWith(
                color: isWeekend ? colors.primary : colors.textTertiary,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
