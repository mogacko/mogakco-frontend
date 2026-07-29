import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/meetup.dart';
import 'join_confirm_sheet.dart';

/// 모임 탭에 놓이는 모임 하나.
///
/// 홈 캐러셀이 하루만 떼어 보여주는 것과 달리 여기서는 그 주에 열리는 날을
/// 모두 늘어놓는다. 토요일만 갈지 이틀 다 갈지는 날들을 나란히 놓고 봐야
/// 정할 수 있고, 참여도 날마다 따로 걸린다.
class MeetupListCard extends StatelessWidget {
  const MeetupListCard({
    super.key,
    required this.meetup,
    required this.now,
    required this.onToggleSession,
  });

  final Meetup meetup;
  final DateTime now;
  final void Function(String sessionId) onToggleSession;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // 이미 지난 날은 뺀다. 목요일에 들어와서 월요일 자리를 보고 있을 이유가 없다.
    final upcoming =
        meetup.sessions.where((session) => session.daysFrom(now) >= 0).toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      // 테두리 대신 면으로 카드를 세운다. 카드가 세로로 쌓이는 자리라
      // 테두리를 두르면 선이 층층이 겹쳐 목록이 사나워진다.
      //
      // Material 로 세우는 이유는 안에 눌리는 줄이 있어서다. 잉크 효과는
      // 가장 가까운 Material 이 그 모양대로 잘라 그린다.
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: _Header(meetup: meetup),
            ),
            for (final session in upcoming) ...[
              Divider(height: 1, color: colors.border),
              _SessionRow(
                meetup: meetup,
                session: session,
                now: now,
                onToggle: () => onToggleSession(session.id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 어디서 누가 여는지
class _Header extends StatelessWidget {
  const _Header({required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                meetup.placeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleLarge,
              ),
            ),
            if (meetup.isRecurring) ...[
              const SizedBox(width: AppSpacing.sm),
              const _RecurringBadge(),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          meetup.shortAddress,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            UserAvatar(
              name: meetup.host,
              imageUrl: meetup.hostAvatarUrl,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                meetup.host,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 매주 열리는 모임이라는 표시.
///
/// 이번 주만 열리는 자리와 구분된다. 꾸준히 나갈 곳을 찾는 사람에게는
/// 이게 장소보다 먼저 걸린다.
class _RecurringBadge extends StatelessWidget {
  const _RecurringBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.repeat, size: 11, color: colors.primary),
          const SizedBox(width: 3),
          Text(
            '정기',
            style: context.texts.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
