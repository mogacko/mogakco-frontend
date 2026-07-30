import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/utils/korean_particle.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../../../shared/widgets/screen_header.dart';
import '../domain/event.dart';
import 'event_detail_screen.dart';
import 'event_provider.dart';
import 'widgets/event_card.dart';

/// 행사 탭.
///
/// 지부가 여는 공식 행사만 모인다. 카페에서 각자 작업하는 모각코 모임은
/// 모임 탭에 있다.
class EventScreen extends ConsumerWidget {
  const EventScreen({super.key});

  /// 필터 항목. 맨 앞의 null 이 '전체'다.
  static const _filters = <EventKind?>[null, ...EventKind.values];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = ref.watch(nowProvider);
    final events = ref.watch(visibleEventsProvider);
    final kind = ref.watch(eventFilterProvider);
    final counts = ref.watch(eventCountsProvider);
    final total = ref.watch(chapterEventsProvider).length;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHeader(title: '행사'),
            FilterBar<EventKind?>(
              options: _filters,
              selected: kind,
              labelOf: (kind) => kind?.label ?? '전체',
              countOf: (kind) => kind == null ? total : (counts[kind] ?? 0),
              onSelect: (kind) =>
                  ref.read(eventFilterProvider.notifier).select(kind),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: PullToRefresh(
                onRefresh: () => ref.read(eventListProvider.notifier).refresh(),
                child: events.isEmpty
                    // 화면 가운데 세우되, 글자를 키운 기기에서 넘치면 스크롤한다.
                    ? Center(
                        child: SingleChildScrollView(
                          physics: alwaysScrollable,
                          child: _Empty(kind: kind),
                        ),
                      )
                    : ListView.separated(
                        physics: alwaysScrollable,
                        padding: EdgeInsets.only(
                          bottom:
                              AppBottomNav.contentInset(context) +
                              AppSpacing.xl,
                        ),
                        itemCount: events.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return EventCard(
                            event: event,
                            now: now,
                            onToggleApply: () => ref
                                .read(eventListProvider.notifier)
                                .toggleApply(event.id),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    EventDetailScreen(eventId: event.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.kind});

  /// 어떤 종류를 보다가 비었는지. null 이면 예정된 행사가 아예 없다.
  final EventKind? kind;

  @override
  Widget build(BuildContext context) {
    if (kind != null) {
      final label = kind!.label;
      return EmptyState(
        icon: CupertinoIcons.ticket,
        title: '예정된 $label${KoreanParticle.subject(label)} 없어요',
        description: '전체에서 다른 행사를 볼 수 있어요',
      );
    }

    return const EmptyState(
      icon: CupertinoIcons.ticket,
      title: '예정된 행사가 없어요',
      // 행사는 운영진이 연다. 사용자가 지금 할 수 있는 일이 없으므로
      // 버튼을 두지 않고 언제 다시 오면 되는지만 알린다.
      description: '새 행사가 열리면 알림으로 알려드릴게요',
    );
  }
}
