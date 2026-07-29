import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/confirm_sheet.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/meetup.dart';

/// 참여를 정하기 전에 어느 모임 어느 날인지 다시 보여준다.
///
/// 버튼 한 번에 신청이 나가면 잘못 눌렀을 때 되돌릴 방법이 없다. 게다가
/// 카드가 옆으로 이어져 있어 이웃 카드를 누르기도 쉽다. 무엇을 고른 것인지
/// 확인하고 결정하게 한다.
///
/// 확인하면 true, 물러나면 false를 돌려준다.
Future<bool> confirmJoinChange(
  BuildContext context, {
  required Meetup meetup,
  required MeetupSession session,
  required DateTime now,
}) {
  final leaving = session.isJoined;

  return showConfirmSheet(
    context,
    title: leaving ? '참여를 취소할까요?' : '이 일정으로 참여할까요?',
    confirmLabel: leaving ? '참여 취소' : '참여하기',
    // 취소는 자리가 곧장 남에게 넘어가 되돌리기 어렵다.
    tone: leaving ? ConfirmTone.danger : ConfirmTone.normal,
    details: _Summary(meetup: meetup, session: session, now: now),
  );
}

/// 무엇을 고른 것인지 한눈에 보여주는 요약
class _Summary extends StatelessWidget {
  const _Summary({
    required this.meetup,
    required this.session,
    required this.now,
  });

  final Meetup meetup;
  final MeetupSession session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ConfirmSummary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meetup.placeName, style: context.texts.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            meetup.shortAddress,
            style: context.texts.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(
                session.whenLabel(now),
                style: context.texts.titleLarge?.copyWith(
                  color: colors.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${session.participantCount} / ${session.capacity}',
                style: context.texts.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              UserAvatar(
                name: meetup.host,
                imageUrl: meetup.hostAvatarUrl,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                meetup.host,
                style: context.texts.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
