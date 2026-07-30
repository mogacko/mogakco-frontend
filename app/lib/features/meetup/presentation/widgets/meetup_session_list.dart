import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/meetup.dart';
import 'join_confirm_sheet.dart';

/// 한 모임의 날짜 줄들.
///
/// 목록 카드와 상세 화면이 같은 것을 쓴다. 같은 결정을 두 화면에서 다른
/// 모양으로 내리게 하면 어느 쪽이 진짜인지 헷갈린다.
///
/// 상자는 두르지 않는다. 카드 안에 들어갈 때와 화면에 바로 놓일 때 감싸는
/// 방식이 달라서, 부르는 쪽이 정한다.
class MeetupSessionList extends StatelessWidget {
  const MeetupSessionList({
    super.key,
    required this.meetup,
    required this.now,
    required this.onToggleSession,
    this.leadingDivider = true,
  });

  final Meetup meetup;
  final DateTime now;
  final void Function(String sessionId) onToggleSession;

  /// 첫 줄 위에 선을 그을지. 카드 안에서는 위쪽 내용과 나눠야 하고,
  /// 상자 하나만 놓일 때는 맨 위에 선이 뜨면 어색하다.
  final bool leadingDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // 이미 지난 날은 뺀다. 목요일에 들어와서 월요일 자리를 보고 있을 이유가 없다.
    final upcoming =
        meetup.sessions.where((session) => session.daysFrom(now) >= 0).toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < upcoming.length; i++) ...[
          if (i > 0 || leadingDivider)
            Divider(height: 1, color: colors.border),
          _SessionRow(
            meetup: meetup,
            session: upcoming[i],
            now: now,
            onToggle: () => onToggleSession(upcoming[i].id),
          ),
        ],
      ],
    );
  }
}

/// 한 날짜 줄.
///
/// 줄 전체가 눌린다. 오른쪽 알약만 누르게 하면 손가락이 닿는 자리가 좁아
/// 옆 날짜를 잘못 누르기 쉽다.
class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.meetup,
    required this.session,
    required this.now,
    required this.onToggle,
  });

  final Meetup meetup;
  final MeetupSession session;
  final DateTime now;
  final VoidCallback onToggle;

  /// 자리가 찼고 아직 신청하지 않았다면 더 할 수 있는 게 없다.
  /// 이미 신청했다면 언제든 뺄 수 있어야 한다.
  bool get _blocked => session.isFull && !session.isJoined;

  Future<void> _confirm(BuildContext context) async {
    final ok = await confirmJoinChange(
      context,
      meetup: meetup,
      session: session,
      now: now,
    );
    if (ok) onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: _blocked ? null : () => _confirm(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // 날짜 칸 너비를 고정해 아래위 줄의 시각이 같은 자리에서 시작한다.
            SizedBox(
              width: 68,
              child: Text(
                session.dayLabel(now),
                style: context.texts.labelMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              session.timeLabel,
              style: context.texts.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const Spacer(),
            _Seats(session: session),
            const SizedBox(width: AppSpacing.md),
            _JoinPill(session: session),
          ],
        ),
      ),
    );
  }
}

/// 남은 자리.
///
/// '5/8'처럼 채워진 수를 그대로 둔다. '3자리 남음'으로 바꾸면 얼마나 붐비는
/// 자리인지가 사라져서, 두 명짜리 모임과 여덟 명짜리 모임이 같아 보인다.
class _Seats extends StatelessWidget {
  const _Seats({required this.session});

  final MeetupSession session;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Text(
      '${session.participantCount}/${session.capacity}',
      style: context.texts.labelSmall?.copyWith(
        // 거의 찬 자리는 서둘러야 한다는 걸 색으로 먼저 알린다.
        color: session.isFull ? colors.hot : colors.textTertiary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// 지금 이 날짜가 어떤 상태인지 보여주는 알약.
///
/// 줄 전체가 눌리므로 이건 눌리는 자리가 아니라 상태 표시다.
class _JoinPill extends StatelessWidget {
  const _JoinPill({required this.session});

  final MeetupSession session;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final joined = session.isJoined;
    final blocked = session.isFull && !joined;

    final (label, background, foreground) = switch ((joined, blocked)) {
      (true, _) => ('참여 중', colors.primary, colors.primaryForeground),
      (_, true) => ('마감', colors.surfaceAlt, colors.textTertiary),
      _ => ('신청', colors.surfaceAlt, colors.primary),
    };

    return Container(
      constraints: const BoxConstraints(minWidth: 56),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm - 1,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: context.texts.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
