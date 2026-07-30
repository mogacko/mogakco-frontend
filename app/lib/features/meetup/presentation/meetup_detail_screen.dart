import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../domain/meetup.dart';
import 'meetup_provider.dart';
import 'widgets/meetup_session_list.dart';
import 'widgets/recurring_badge.dart';

/// 모각코 하나.
///
/// 목록 카드와 겹치는 게 많다. 다른 점은 소개글이 여기서만 보이고, 주소를
/// 시·도까지 그대로 둔다는 것이다.
///
/// 모임 객체가 아니라 id 를 받는다. 객체를 넘기면 참여를 누른 뒤에도 화면이
/// 들어올 때의 값을 그대로 들고 있다.
class MeetupDetailScreen extends ConsumerWidget {
  const MeetupDetailScreen({super.key, required this.meetupId});

  final String meetupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final meetup = ref
        .watch(meetupListProvider)
        .where((meetup) => meetup.id == meetupId)
        .firstOrNull;

    if (meetup == null) {
      return const DetailScaffold(
        children: [
          EmptyState(
            icon: CupertinoIcons.person_2,
            title: '모각코를 찾을 수 없어요',
            description: '닫혔거나 지워진 모임일 수 있어요',
          ),
        ],
      );
    }

    final description = meetup.description;

    return DetailScaffold(
      children: [
        _Head(meetup: meetup),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Text(description, style: context.texts.bodyLarge),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Text('이번 주 일정', style: context.texts.titleLarge),
        ),
        const SizedBox(height: AppSpacing.md),
        // 날짜 줄은 목록 카드와 같은 것을 쓴다. 같은 결정을 두 화면에서 다른
        // 모양으로 내리게 하면 어느 쪽이 진짜인지 헷갈린다.
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Material(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: MeetupSessionList(
              meetup: meetup,
              now: now,
              // 상자 하나만 놓이므로 맨 위에는 선을 긋지 않는다.
              leadingDivider: false,
              onToggleSession: (sessionId) => ref
                  .read(meetupListProvider.notifier)
                  .toggleSession(meetup.id, sessionId),
            ),
          ),
        ),
      ],
    );
  }
}

/// 어디서 누가 여는지
class _Head extends StatelessWidget {
  const _Head({required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  meetup.placeName,
                  style: context.texts.headlineMedium,
                ),
              ),
              if (meetup.isRecurring) ...[
                const SizedBox(width: AppSpacing.sm),
                const RecurringBadge(),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // 상세에서는 시·도까지 그대로 둔다. 목록과 달리 지도 앱에 옮겨
          // 붙이거나 누구에게 알려주는 자리다.
          Text(
            meetup.address,
            style: context.texts.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              UserAvatar(
                name: meetup.host,
                imageUrl: meetup.hostAvatarUrl,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meetup.host,
                    style: context.texts.labelMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text('모임장', style: context.texts.labelSmall),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
