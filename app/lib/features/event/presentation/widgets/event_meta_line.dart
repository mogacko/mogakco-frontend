import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/event.dart';

/// 제목 위에 놓는 한 줄. '7/31 (금) · 네트워킹 · D-1'
///
/// 셋을 붙여 둔다. 언제 하고 어떤 자리이고 언제까지 신청하는지는 모두 같은
/// 성격이라, 하나만 줄 끝으로 밀어내면 딴 데 있는 것처럼 보인다.
///
/// Row 로 늘어놓지 않고 한 덩이 글로 둔다. 글꼴을 키우면 Row 는 넘쳐서 터지는데
/// 글은 알아서 줄임표로 접힌다.
class EventMetaLine extends StatelessWidget {
  const EventMetaLine({super.key, required this.event, required this.now});

  final Event event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // 마감이 코앞일 때만 눈에 띄게 한다. 모든 행사에 빨간 표시가 붙으면
    // 정말 급한 것이 묻힌다.
    final urgent = event.isUrgent(now) && !event.isFull;

    TextSpan bold(String text, Color color) => TextSpan(
      text: text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    );

    return Text.rich(
      TextSpan(
        style: context.texts.labelSmall,
        children: [
          bold(event.shortDateLabel, colors.textSecondary),
          const TextSpan(text: ' · '),
          bold(event.kind.label, colors.primary),
          const TextSpan(text: ' · '),
          bold(
            event.ddayLabel(now),
            urgent ? colors.hot : colors.textTertiary,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
