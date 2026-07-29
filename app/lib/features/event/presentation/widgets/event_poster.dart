import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/event.dart';
import 'event_date_block.dart';

/// 행사 목록 왼쪽에 세우는 포스터.
///
/// 포스터가 있으면 날짜 칸 대신 이걸 세운다. 둘 다 두면 제목이 열 자쯤에서
/// 잘리고, 무엇보다 포스터가 날짜보다 그 행사를 잘 말한다.
///
/// 포스터가 없거나 못 불러오면 날짜 칸으로 물러난다. 자리가 비면 목록이
/// 들쭉날쭉해지고, 지부가 매번 포스터를 만들지는 않아서 흔한 경우다.
/// 크기를 날짜 칸과 똑같이 잡아 두 경우가 같은 줄에 섞여도 어긋나지 않는다.
class EventPoster extends StatelessWidget {
  const EventPoster({super.key, required this.event, this.compact = false});

  final Event event;

  /// 홈처럼 좁은 자리에 놓을 때
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final url = event.posterUrl;
    final fallback = EventDateBlock(date: event.startsAt, compact: compact);

    if (url == null) return fallback;

    final size = EventDateBlock.sizeOf(compact: compact);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Image.network(
        url,
        width: size.width,
        height: size.height,
        // 포스터는 대개 세로로 길다. 상자에 맞춰 잘라 줄 높이를 지킨다.
        fit: BoxFit.cover,
        // 받아오는 동안 자리를 비워두면 목록이 한 번 출렁인다.
        // 날짜 칸이 같은 상자를 쓰므로 그대로 세워 둔다.
        frameBuilder: (context, child, frame, wasSynchronous) {
          if (wasSynchronous || frame != null) return child;
          return fallback;
        },
        errorBuilder: (context, _, _) => fallback,
      ),
    );
  }
}
