import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/utils/korean_particle.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/paged.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/title_menu.dart';
import '../domain/event.dart';
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
    final paged = ref.watch(pagedEventsProvider);
    final events = paged.items;
    final kind = ref.watch(eventFilterProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 종류를 제목 자리로 올린다. 행사 탭이라는 건 탭 바가 이미
            // 말하고 있어, 제목에 '행사'를 한 번 더 적을 이유가 없다.
            ScreenHeader.custom(
              titleWidget: TitleMenu<EventKind?>(
                current: kind,
                options: _filters,
                labelOf: (kind) => kind?.label ?? '전체',
                tooltip: '종류 바꾸기',
                onSelected: (kind) =>
                    ref.read(eventFilterProvider.notifier).select(kind),
              ),
              actions: [
                HeaderAction(
                  icon: CupertinoIcons.plus,
                  label: '행사 올리기',
                  emphasized: true,
                  onTap: () => context.push(AppRoute.eventCreate),
                ),
              ],
            ),
            Expanded(
              child: LoadMoreOnScroll(
                canLoadMore:
                    paged.hasMore &&
                    !paged.isLoadingMore &&
                    paged.error == null,
                onLoadMore: () =>
                    ref.read(eventPagingProvider.notifier).loadMore(),
                child: PullToRefresh(
                  onRefresh: () async {
                    // 새로 받아오면 페이지도 처음으로 되돌린다.
                    ref.read(eventPagingProvider.notifier).reset();
                    await ref.read(eventListProvider.notifier).refresh();
                  },
                  slivers: [
                    if (events.isEmpty)
                      // 남는 자리를 다 차지해 가운데 세운다.
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: _Empty(kind: kind)),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom:
                              AppBottomNav.contentInset(context) +
                              AppSpacing.xl,
                        ),
                        sliver: SliverList.separated(
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
                              onTap: () =>
                                  context.push(AppRoute.event(event.id)),
                            );
                          },
                        ),
                      ),
                    if (events.isNotEmpty)
                      SliverToBoxAdapter(
                        child: PagedFooter(
                          state: paged,
                          onRetry: () =>
                              ref.read(eventPagingProvider.notifier).loadMore(),
                        ),
                      ),
                  ],
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
