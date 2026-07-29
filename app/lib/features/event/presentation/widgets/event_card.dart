import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/event.dart';
import 'event_apply_sheet.dart';
import 'event_poster.dart';

/// 행사 탭에 놓이는 행사 하나.
///
/// 왼쪽에 날짜를 달력처럼 세운다. 행사는 '무엇을 하느냐'만큼 '언제 하느냐'로
/// 고르게 되는데, 날짜가 본문 속 한 줄로 섞여 있으면 목록을 훑으며 비교할 수
/// 없다.
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
              EventPoster(event: event),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          event.kind.label,
                          style: context.texts.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // 포스터가 왼쪽 자리를 가져갔으므로 날짜를 여기서
                        // 말한다. 포스터가 없으면 날짜 칸이 그대로 있다.
                        if (event.posterUrl != null) ...[
                          Text(' · ', style: context.texts.labelSmall),
                          Text(
                            event.shortDateLabel,
                            style: context.texts.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        _Dday(event: event, now: now),
                      ],
                    ),
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

/// 신청 마감까지 남은 날.
///
/// 마감이 코앞일 때만 눈에 띄게 한다. 모든 행사에 빨간 표시가 붙으면
/// 정말 급한 것이 묻힌다.
class _Dday extends StatelessWidget {
  const _Dday({required this.event, required this.now});

  final Event event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final urgent = event.isUrgent(now) && !event.isFull;

    return Text(
      event.ddayLabel(now),
      style: context.texts.labelSmall?.copyWith(
        color: urgent ? colors.hot : colors.textTertiary,
        fontWeight: FontWeight.w600,
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
