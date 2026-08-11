import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/meetup.dart';
import 'cancelled_notice.dart';
import 'meetup_session_list.dart';
import 'recurring_badge.dart';

/// 모각코 탭에 놓이는 모임 하나.
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
    this.onTap,
    this.showChapter = false,
  });

  final Meetup meetup;
  final DateTime now;
  final void Function(String sessionId) onToggleSession;

  /// 시·도를 떼지 않고 그대로 둘지.
  ///
  /// 지역을 넘나드는 목록('내 활동')에서 켠다. 모각코 탭은 한 지역만 보고
  /// 있어서 '부산광역시'가 열 줄 내리 반복되면 정작 다른 부분인 구·동이
  /// 뒤로 밀린다.
  final bool showChapter;

  /// 카드 위쪽(장소·모임장)을 누르면 상세로 간다.
  ///
  /// 날짜 줄은 그 자리에서 참여를 정하는 곳이라 상세로 가지 않는다. 한 카드에
  /// 목적이 둘이라 눌리는 자리를 나눠 둔다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      // 라이트에서는 면으로만 세운다(cardBorder 가 투명). 카드가 세로로
      // 쌓이는 자리라 선을 두르면 층층이 겹쳐 목록이 사나워진다.
      //
      // Material 로 세우는 이유는 안에 눌리는 줄이 있어서다. 잉크 효과는
      // 가장 가까운 Material 이 그 모양대로 잘라 그린다.
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        // 다크에서만 보이는 선. 어두운 쪽에서는 면 차이로 경계가 안 잡힌다.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: _Header(meetup: meetup, showChapter: showChapter),
              ),
            ),
            MeetupSessionList(
              meetup: meetup,
              now: now,
              onToggleSession: onToggleSession,
            ),
          ],
        ),
      ),
    );
  }
}

/// 어디서 누가 여는지
class _Header extends StatelessWidget {
  const _Header({required this.meetup, required this.showChapter});

  final Meetup meetup;
  final bool showChapter;

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
              const RecurringBadge(),
            ],
          ],
        ),
        const SizedBox(height: 2),
        if (meetup.isCancelled) ...[
          CancelledLine(cancellation: meetup.cancellation!),
          const SizedBox(height: 2),
        ],
        Text(
          showChapter ? meetup.address : meetup.shortAddress,
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
