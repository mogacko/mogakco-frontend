import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../member/presentation/member_provider.dart';
import '../../domain/meetup.dart';

/// 이 모임에 오는 사람들.
///
/// 날짜별로 나눠 세운다. 한 줄로 합치면 토요일에만 오는 사람과 이틀 다 오는
/// 사람이 섞여, 내가 가는 날 누가 있는지를 알 수 없다.
///
/// 얼굴만 늘어놓지 않고 이름을 함께 둔다. 아는 사람이 있는지 확인하러 보는
/// 자리인데, 사진이 없는 사람은 이니셜만 남아 누구인지 알 수 없다.
class ParticipantRoster extends ConsumerWidget {
  const ParticipantRoster({super.key, required this.meetup, required this.now});

  final Meetup meetup;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 지난 날은 뺀다. 누가 왔었는지보다 누가 올 것인지가 궁금한 자리다.
    final upcoming = meetup.sessions
        .where((session) => session.daysFrom(now) >= 0)
        .where((session) => session.participants.isNotEmpty)
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    final me = ref.watch(myIdProvider);
    final single = upcoming.length == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Text('참여하는 사람', style: context.texts.titleLarge),
        ),
        for (final session in upcoming) ...[
          const SizedBox(height: AppSpacing.md),
          // 하루짜리 모임에 '오늘'이라고 또 적으면 바로 위 일정과 같은 말이
          // 두 번이다.
          if (!single)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.screenHorizontal,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                '${session.dayLabel(now)} ${session.timeLabel}',
                style: context.texts.labelSmall,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final id in session.participants)
                  _PersonChip(
                    id: id,
                    isMe: id == me,
                    isHost: id == meetup.host,
                    onTap: () => context.push(AppRoute.member(id)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 사람 한 명. 눌러서 프로필로 들어간다.
class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.id,
    required this.isMe,
    required this.isHost,
    required this.onTap,
  });

  final String id;
  final bool isMe;
  final bool isHost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.full),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(name: id, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                id,
                style: context.texts.labelMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // 모임장과 나는 표시해 둔다. 열 명쯤 늘어놓으면 누가 연 자리인지
              // 위로 다시 올라가 확인해야 한다.
              if (isHost || isMe) ...[
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  isHost ? '모임장' : '나',
                  style: context.texts.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
