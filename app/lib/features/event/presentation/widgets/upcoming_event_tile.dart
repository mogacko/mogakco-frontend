import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/event.dart';
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
    final colors = context.colors;
    final urgent = event.isUrgent(now) && !event.isFull;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            EventPoster(event: event, compact: true),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 포스터가 왼쪽 자리를 가져갔으므로 날짜를 여기서 말한다.
                      // 포스터가 없는 행사는 날짜 칸이 그대로라 여기서는 뺀다.
                      if (event.posterUrl != null) ...[
                        Text(
                          event.shortDateLabel,
                          style: context.texts.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(' · ', style: context.texts.labelSmall),
                      ],
                      Text(
                        event.kind.label,
                        style: context.texts.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        event.ddayLabel(now),
                        style: context.texts.labelSmall?.copyWith(
                          // 마감이 코앞일 때만 눈에 띄게 한다.
                          color: urgent ? colors.hot : colors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
          ],
        ),
      ),
    );
  }
}
