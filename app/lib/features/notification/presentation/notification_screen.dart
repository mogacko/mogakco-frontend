import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/utils/relative_time.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/app_notification.dart';
import 'notification_provider.dart';

/// 알림 목록.
///
/// 안 읽은 것과 읽은 것을 나눠 쌓지 않는다. 나누면 방금 읽은 알림이 목록
/// 아래로 순간이동해서, 무엇을 읽었는지 다시 찾아야 한다. 순서는 시간 그대로
/// 두고 읽음 여부는 색으로만 가른다.
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(chapterNotificationsProvider);
    final hasUnread = ref.watch(hasUnreadProvider);

    return DetailScaffold(
      title: '알림',
      onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
      actions: [
        if (hasUnread)
          TextButton(
            onPressed: () {
              Haptics.toggle();
              ref.read(notificationListProvider.notifier).markAllRead();
            },
            child: const Text('모두 읽음'),
          ),
      ],
      children: [
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.huge),
            child: EmptyState(
              icon: CupertinoIcons.bell,
              title: '아직 알림이 없어요',
              description: '댓글이 달리거나 모임이 다가오면 여기로 알려드릴게요',
            ),
          )
        else
          for (final item in items)
            _NotificationRow(
              item: item,
              onTap: () {
                ref.read(notificationListProvider.notifier).markRead(item.id);
                final route = item.route;
                if (route != null) context.push(route);
              },
            ),
      ],
    );
  }
}

/// 알림 한 줄.
///
/// 안 읽은 것은 왼쪽에 점을 찍고 제목을 진하게 둔다. 배경색으로 가르는 방법도
/// 있지만, 목록 절반이 색 띠가 되면 정작 무슨 알림인지가 뒤로 밀린다.
class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  /// 점이 들어갈 자리. 읽은 줄도 이만큼 비워 둬야 글 시작선이 어긋나지 않는다.
  static const _dotColumn = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = ref.watch(nowProvider);
    final unread = !item.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _dotColumn,
                child: unread
                    ? Padding(
                        // 제목 첫 줄 가운데에 맞춘다.
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              Icon(
                _icon(item.kind),
                size: AppSize.iconSm,
                // 종류를 색으로 가르지 않는다. 다섯 색이 세로로 쌓이면 목록이
                // 알림보다 시끄러워진다. 모양만으로 충분히 갈린다.
                color: unread ? colors.textSecondary : colors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: context.texts.bodyMedium?.copyWith(
                        color: unread
                            ? colors.textPrimary
                            : colors.textSecondary,
                        fontWeight: unread
                            ? FontWeight.w600
                            : FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    if (item.body != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.body!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall?.copyWith(
                          color: unread
                              ? colors.textSecondary
                              : colors.textTertiary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      relativeTime(item.createdAt, now),
                      style: context.texts.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _icon(NotificationKind kind) => switch (kind) {
    NotificationKind.comment => CupertinoIcons.chat_bubble,
    NotificationKind.like => CupertinoIcons.heart,
    NotificationKind.join => CupertinoIcons.person_add,
    NotificationKind.upcoming => CupertinoIcons.clock,
    NotificationKind.notice => CupertinoIcons.speaker_2,
  };
}
