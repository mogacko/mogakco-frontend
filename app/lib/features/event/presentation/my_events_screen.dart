import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/event.dart';
import 'event_provider.dart';

/// 내가 올린 행사.
///
/// 검토 중인 행사는 목록에 안 선다. 이 자리가 없으면 낸 사람도 자기 행사가
/// 어떻게 됐는지 볼 데가 없다.
class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(myEventsProvider);

    return DetailScaffold(
      title: '내가 올린 행사',
      children: [
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.huge),
            child: EmptyState(
              icon: CupertinoIcons.ticket,
              title: '올린 행사가 없어요',
              description: '세미나나 해커톤을 열고 싶으면 여기서 올릴 수 있어요',
              actionLabel: '행사 올리기',
              onAction: () => context.push(AppRoute.eventCreate),
            ),
          )
        else
          for (final event in events)
            _MyEventRow(
              event: event,
              // 등록된 것만 상세로 들어간다. 검토 중인 행사는 아직 목록에
              // 없어서 열어도 '찾을 수 없어요'가 뜬다.
              onTap: event.isApproved
                  ? () => context.push(AppRoute.event(event.id))
                  : null,
            ),
      ],
    );
  }
}

class _MyEventRow extends StatelessWidget {
  const _MyEventRow({required this.event, required this.onTap});

  final Event event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusBadge(status: event.status),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${event.startsAt.month}/${event.startsAt.day}',
                    style: context.texts.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                // 반려됐으면 왜 안 됐는지가 가장 먼저 필요하다. 그게 없으면
                // 같은 걸 그대로 다시 올린다.
                event.rejectionNote ?? event.status.description,
                style: context.texts.bodyMedium?.copyWith(
                  color: event.status == EventStatus.rejected
                      ? colors.danger
                      : colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // 검토 중은 아직 아무 일도 안 일어난 상태다. 색으로 재촉하지 않는다.
    final (background, foreground) = switch (status) {
      EventStatus.pending => (colors.surfaceAlt, colors.textSecondary),
      EventStatus.approved => (colors.surfaceAlt, colors.primary),
      EventStatus.rejected => (colors.surfaceAlt, colors.danger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        status.label,
        style: context.texts.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
