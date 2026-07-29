import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/event.dart';
import 'event_apply_sheet.dart';
import 'event_meta_line.dart';
import 'event_poster.dart';

/// 행사 탭에 놓이는 행사 하나.
///
/// 글이 왼쪽에서 시작하고 포스터가 오른쪽에서 거든다. 이 목록은 무엇을 하는
/// 자리인지 읽으러 오는 곳이라, 눈이 먼저 닿는 왼쪽을 글에 내준다.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.now,
    required this.onToggleApply,
  });

  final Event event;
  final DateTime now;
  final VoidCallback onToggleApply;

  Future<void> _confirm(BuildContext context) async {
    final ok = await confirmEventApply(context, event: event, now: now);
    if (ok) onToggleApply();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final closed = event.isClosed(now);
    final poster = event.posterUrl;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜는 포스터가 있든 없든 늘 여기 있다. 자리가 왔다 갔다
                    // 하면 매번 어디를 봐야 할지 다시 찾게 된다.
                    EventMetaLine(event: event, now: now),
                    const SizedBox(height: 2),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      event.venue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // 시각·참가비·자리는 각각 한 줄을 차지할 만큼 무겁지 않다.
                    // 가운뎃점으로 이어 한 줄에 눕힌다.
                    Text(
                      '${event.timeRangeLabel} · ${event.feeLabel} · '
                      '${event.applicantCount}/${event.capacity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelSmall,
                    ),
                  ],
                ),
              ),
              // 없으면 세우지 않는다. 빈 상자를 남기면 무언가 빠진 것처럼 보인다.
              if (poster != null) ...[
                const SizedBox(width: AppSpacing.lg),
                EventPoster(url: poster),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: _ApplyButton(
              event: event,
              closed: closed,
              onTap: () => _confirm(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({
    required this.event,
    required this.closed,
    required this.onTap,
  });

  final Event event;
  final bool closed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final applied = event.isApplied;

    // 신청했다면 마감됐더라도 뺄 수는 있어야 한다.
    final blocked = closed && !applied;

    final label = switch ((applied, blocked, event.isFull)) {
      (true, _, _) => '신청 완료',
      (_, true, true) => '정원 마감',
      (_, true, _) => '신청 마감',
      _ => '신청하기',
    };

    final (background, foreground) = switch ((applied, blocked)) {
      // 신청을 마친 뒤에는 그 사실을 알리기만 하면 된다. 채운 버튼으로 두면
      // 아직 할 일이 남은 것처럼 계속 재촉한다.
      (true, _) => (colors.surfaceAlt, colors.primary),
      (_, true) => (colors.surfaceAlt, colors.textTertiary),
      _ => (colors.primary, colors.primaryForeground),
    };

    return Semantics(
      button: !blocked,
      selected: applied,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: blocked ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md - 2,
            ),
            child: Text(
              label,
              style: context.texts.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
