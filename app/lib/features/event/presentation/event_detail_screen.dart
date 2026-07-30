import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/event.dart';
import 'event_provider.dart';
import 'widgets/event_apply_sheet.dart';
import 'widgets/event_info_line.dart';
import 'widgets/event_meta_line.dart';

/// 행사 하나.
///
/// 목록에서 줄인 것들을 여기서 다 펼친다. 포스터는 크게, 설명은 통째로,
/// 일시·장소·참가비·마감은 라벨을 붙여 줄줄이 세운다. 돈과 시간을 쓰는
/// 결정이라 목록의 한 줄 요약으로는 정하기 어렵다.
///
/// 행사 객체가 아니라 id 를 받는다. 객체를 넘기면 신청한 뒤에도 화면이
/// 들어올 때의 값을 그대로 들고 있다.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final event = ref
        .watch(eventListProvider)
        .where((event) => event.id == eventId)
        .firstOrNull;

    if (event == null) {
      return const DetailScaffold(
        children: [
          EmptyState(
            icon: CupertinoIcons.ticket,
            title: '행사를 찾을 수 없어요',
            description: '이미 끝났거나 내려간 행사일 수 있어요',
          ),
        ],
      );
    }

    final poster = event.posterUrl;
    final colors = context.colors;

    return DetailScaffold(
      bottomAction: _ApplyButton(event: event, now: now),
      children: [
        if (poster != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: AspectRatio(
                // 목록에서는 정사각으로 잘랐지만 여기서는 포스터를 보러 온
                // 자리다. 가로로 넓게 둬서 글자가 읽히게 한다.
                aspectRatio: 4 / 3,
                child: Image.network(
                  poster,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) =>
                      ColoredBox(color: colors.surfaceAlt),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventMetaLine(event: event, now: now),
              const SizedBox(height: AppSpacing.xs),
              Text(event.title, style: context.texts.headlineMedium),
              const SizedBox(height: AppSpacing.lg),
              Text(event.summary, style: context.texts.bodyLarge),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EventInfoLine(
                label: '일시',
                value: '${event.dateLabel} ${event.timeRangeLabel}',
              ),
              const SizedBox(height: AppSpacing.md),
              EventInfoLine(label: '장소', value: event.venue),
              const SizedBox(height: AppSpacing.md),
              EventInfoLine(
                label: '참가비',
                value: event.feeLabel,
                emphasized: !event.isFree,
              ),
              const SizedBox(height: AppSpacing.md),
              EventInfoLine(
                label: '정원',
                value: '${event.applicantCount} / ${event.capacity}명',
              ),
              const SizedBox(height: AppSpacing.md),
              EventInfoLine(
                label: '신청 마감',
                value:
                    '${event.applyBy.month}월 ${event.applyBy.day}일 '
                    '(${event.ddayLabel(now)})',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 화면 아래에 붙는 신청 버튼.
///
/// 목록의 알약과 달리 폭을 다 쓴다. 여기까지 읽고 내리는 결정이라 망설일
/// 이유를 하나라도 줄인다.
class _ApplyButton extends ConsumerWidget {
  const _ApplyButton({required this.event, required this.now});

  final Event event;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final applied = event.isApplied;

    // 신청했다면 마감됐더라도 뺄 수는 있어야 한다.
    final blocked = event.isClosed(now) && !applied;

    final label = switch ((applied, blocked, event.isFull)) {
      (true, _, _) => '신청 취소',
      (_, true, true) => '정원이 찼어요',
      (_, true, _) => '신청이 마감됐어요',
      _ => '신청하기',
    };

    return FilledButton(
      style: applied
          // 취소는 되돌리기 어려운 쪽이라 색으로 구분한다.
          ? FilledButton.styleFrom(
              backgroundColor: colors.surfaceAlt,
              foregroundColor: colors.danger,
            )
          : null,
      onPressed: blocked
          ? null
          : () async {
              final ok = await confirmEventApply(
                context,
                event: event,
                now: now,
              );
              if (ok) {
                ref.read(eventListProvider.notifier).toggleApply(event.id);
              }
            },
      child: Text(label),
    );
  }
}
