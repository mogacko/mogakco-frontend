import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/meetup.dart';

/// 참여를 정하기 전에 어느 모임 어느 날인지 다시 보여준다.
///
/// 버튼 한 번에 신청이 나가면 잘못 눌렀을 때 되돌릴 방법이 없다. 게다가
/// 카드가 옆으로 이어져 있어 이웃 카드를 누르기도 쉽다. 무엇을 고른 것인지
/// 확인하고 결정하게 한다.
///
/// 시스템 얼럿 대신 시트를 쓰는 이유는 보여줄 게 장소·주소·시각·인원·모임장
/// 다섯 가지라서다. 텍스트로 늘어놓으면 눈에 들어오지 않는다.
///
/// 확인하면 true, 물러나면 false를 돌려준다.
Future<bool> confirmJoinChange(
  BuildContext context, {
  required Meetup meetup,
  required MeetupSession session,
  required DateTime now,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    // 기본 최대 높이가 화면의 절반이라 내용이 잘린다. 내용만큼 차지하게 둔다.
    isScrollControlled: true,
    // 시트 안에서 화면 크기를 재므로 안전영역을 직접 다룬다.
    useSafeArea: true,
    builder: (context) =>
        _JoinConfirmSheet(meetup: meetup, session: session, now: now),
  );

  return result ?? false;
}

class _JoinConfirmSheet extends StatelessWidget {
  const _JoinConfirmSheet({
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
    final leaving = session.isJoined;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      // 화면이 짧거나 글꼴을 키우면 내용이 넘친다. 그때는 시트 안에서 스크롤한다.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 아래로 내려 닫을 수 있다는 표시.
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              leaving ? '참여를 취소할까요?' : '이 일정으로 참여할까요?',
              style: context.texts.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            _Summary(meetup: meetup, session: session, now: now),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              style: leaving
                  // 취소는 되돌리기 어려운 쪽이라 색으로 구분한다.
                  ? FilledButton.styleFrom(backgroundColor: colors.danger)
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(leaving ? '참여 취소' : '참여하기'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }
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

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
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
