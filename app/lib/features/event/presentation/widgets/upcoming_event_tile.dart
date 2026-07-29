import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/event.dart';
import 'event_meta_line.dart';
import 'event_poster.dart';

/// 홈에 세우는 다가오는 행사 한 줄.
///
/// 행사 탭의 [EventCard] 와 달리 신청 버튼을 두지 않는다. 홈에서는 무엇이
/// 다가오는지만 알면 되고, 참가비와 정원까지 견주려면 어차피 탭으로 넘어가야
/// 한다. 버튼을 두면 홈에서 결정을 재촉하는 꼴이 된다.
class UpcomingEventTile extends StatelessWidget {
  const UpcomingEventTile({
    super.key,
    required this.event,
    required this.now,
    this.onTap,
  });

  final Event event;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final poster = event.posterUrl;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜는 포스터가 있든 없든 늘 여기 있다. 자리가 왔다 갔다
                  // 하면 매번 어디를 봐야 할지 다시 찾게 된다.
                  EventMetaLine(event: event, now: now),
                  const SizedBox(height: 1),
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    event.venue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.labelSmall,
                  ),
                ],
              ),
            ),
            // 없으면 세우지 않는다. 빈 상자를 남기면 무언가 빠진 것처럼 보인다.
            if (poster != null) ...[
              const SizedBox(width: AppSpacing.md),
              EventPoster(url: poster, size: EventPoster.compactSize),
            ],
          ],
        ),
      ),
    );
  }
}
