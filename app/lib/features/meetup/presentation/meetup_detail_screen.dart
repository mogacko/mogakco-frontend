import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../member/presentation/member_provider.dart';
import '../../safety/domain/report.dart';
import '../../safety/presentation/widgets/safety_menu.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/static_map.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../comment/domain/comment.dart';
import '../../comment/presentation/comment_provider.dart';
import '../../comment/presentation/widgets/comment_section.dart';
import '../domain/meetup.dart';
import 'meetup_provider.dart';
import 'widgets/meetup_session_list.dart';
import 'widgets/cancel_sheet.dart';
import 'widgets/cancelled_notice.dart';
import 'widgets/participant_roster.dart';
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

  CommentThread get _thread => (target: CommentTarget.meetup, id: meetupId);

  /// 길찾기는 지도 앱이 훨씬 잘한다. 여기서 흉내 내지 않고 넘긴다.
  ///
  /// 앱이 없으면 브라우저의 네이버 지도가 열린다. 열지 못하는 환경이라도
  /// 주소가 화면에 그대로 있으므로 막히지 않는다.
  Future<void> _openMap(Meetup meetup) async {
    await launchUrl(
      naverMapLink(
        name: meetup.placeName,
        latitude: meetup.latitude!,
        longitude: meetup.longitude!,
      ),
      mode: LaunchMode.externalApplication,
    );
  }

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
    final comments = ref.watch(commentsOfProvider(_thread));

    return DetailScaffold(
      actions: [
        // 내가 연 자리에는 신고가 아니라 접기가 붙는다.
        if (meetup.host == ref.watch(myIdProvider) && !meetup.isCancelled)
          _CancelMenuButton(meetup: meetup, now: now)
        else
          SafetyMenuButton(
            target: ReportTarget.meetup,
            targetId: meetup.id,
            authorId: meetup.host,
          ),
      ],
      // 본체와 댓글을 함께 다시 읽는다. 정원만 바뀌고 댓글은 그대로면
      // 새로고침이 반쯤 된 것처럼 보인다.
      onRefresh: () => Future.wait([
        ref.read(meetupListProvider.notifier).refresh(),
        ref.read(commentListProvider.notifier).refresh(),
      ]),
      // 글 상세와 같은 자리에 같은 입력줄을 둔다. 물어볼 게 생기는 자리는
      // 성격이 같다 — 글에는 '어떻게 하셨어요', 모각코에는 '몇 시까지 가면
      // 되나요'.
      bottomAction: CommentField(
        onSubmit: (body) {
          Haptics.toggle();
          ref.read(commentListProvider.notifier).add(_thread, body);
        },
      ),
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
        // 주소만 있으면 어디쯤인지 감이 안 온다. 처음 가는 카페가 대부분이라
        // 동네를 눈으로 확인하고 나서 갈지 정한다.
        if (meetup.hasLocation) ...[
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StaticMap(
                  latitude: meetup.latitude!,
                  longitude: meetup.longitude!,
                  onOpen: () => _openMap(meetup),
                ),
                const SizedBox(height: AppSpacing.sm),
                OpenInMapButton(onTap: () => _openMap(meetup)),
              ],
            ),
          ),
        ],
        if (meetup.isCancelled) ...[
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: CancelledNotice(
              cancellation: meetup.cancellation!,
              now: now,
            ),
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
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(color: context.colors.cardBorder),
            ),
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
        const SizedBox(height: AppSpacing.xxl),
        ParticipantRoster(meetup: meetup, now: now),
        const SizedBox(height: AppSpacing.xxl),
        Divider(height: 1, color: context.colors.border),
        const SizedBox(height: AppSpacing.xl),
        CommentSection(
          comments: comments,
          now: now,
          onDelete: (comment) =>
              ref.read(commentListProvider.notifier).remove(comment.id),
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
          // 모임장을 눌러 프로필로 들어간다. 누구랑 만나는 자리인지가 참여를
          // 정하는 데 꽤 크게 작용한다.
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => context.push(AppRoute.member(meetup.host)),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 모임장에게만 붙는 '⋯'. 지금은 접기 하나뿐이다.
class _CancelMenuButton extends ConsumerWidget {
  const _CancelMenuButton({required this.meetup, required this.now});

  final Meetup meetup;
  final DateTime now;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final cancellation = await showCancelSheet(
      context,
      now: now,
      participantCount: meetup.totalParticipants,
    );
    if (cancellation == null || !context.mounted) return;

    ref.read(meetupListProvider.notifier).cancel(meetup.id, cancellation);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('모각코를 접었어요. 참여자에게 알려드릴게요'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: '모각코 접기',
      child: InkWell(
        onTap: () => _cancel(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            CupertinoIcons.ellipsis,
            size: AppSize.iconMd,
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
