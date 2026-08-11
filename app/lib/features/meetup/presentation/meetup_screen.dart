import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/paged.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../../../shared/widgets/screen_header.dart';
import 'meetup_provider.dart';
import 'widgets/meetup_list_card.dart';

/// 모임 탭.
///
/// 홈이 오늘 하루만 떼어 보여준다면 여기서는 이번 주에 열리는 모임을 모두
/// 늘어놓는다. 어느 날 갈지 고르는 자리다.
class MeetupScreen extends ConsumerWidget {
  const MeetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = ref.watch(nowProvider);
    final paged = ref.watch(pagedMeetupsProvider);
    final meetups = paged.items;
    final filter = ref.watch(meetupFilterProvider);
    final counts = ref.watch(meetupCountsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: '모각코',
              actions: [
                HeaderAction(
                  icon: CupertinoIcons.add,
                  label: '모각코 만들기',
                  emphasized: true,
                  onTap: () => context.push(AppRoute.meetupCreate),
                ),
              ],
            ),
            FilterBar<MeetupFilter>(
              options: MeetupFilter.values,
              selected: filter,
              labelOf: (filter) => filter.label,
              countOf: (filter) => counts[filter] ?? 0,
              onSelect: (filter) =>
                  ref.read(meetupFilterProvider.notifier).select(filter),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: LoadMoreOnScroll(
                canLoadMore:
                    paged.hasMore &&
                    !paged.isLoadingMore &&
                    paged.error == null,
                onLoadMore: () =>
                    ref.read(meetupPagingProvider.notifier).loadMore(),
                child: PullToRefresh(
                  onRefresh: () async {
                    // 새로 받아오면 페이지도 처음으로 되돌린다.
                    ref.read(meetupPagingProvider.notifier).reset();
                    await ref.read(meetupListProvider.notifier).refresh();
                  },
                  slivers: [
                    if (meetups.isEmpty)
                      // 남는 자리를 다 차지해 가운데 세운다.
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: _Empty(filter: filter)),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom:
                              AppBottomNav.contentInset(context) +
                              AppSpacing.xl,
                        ),
                        sliver: SliverList.separated(
                          itemCount: meetups.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final meetup = meetups[index];
                            return MeetupListCard(
                              meetup: meetup,
                              now: now,
                              onToggleSession: (sessionId) => ref
                                  .read(meetupListProvider.notifier)
                                  .toggleSession(meetup.id, sessionId),
                              onTap: () =>
                                  context.push(AppRoute.meetup(meetup.id)),
                            );
                          },
                        ),
                      ),
                    if (meetups.isNotEmpty)
                      SliverToBoxAdapter(
                        child: PagedFooter(
                          state: paged,
                          onRetry: () => ref
                              .read(meetupPagingProvider.notifier)
                              .loadMore(),
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
  const _Empty({required this.filter});

  final MeetupFilter filter;

  @override
  Widget build(BuildContext context) {
    // 왜 비었는지에 따라 다음에 할 일이 다르다. 아직 아무 데도 신청하지
    // 않은 것과 이 지역에 모임 자체가 없는 것은 같은 화면일 수 없다.
    return switch (filter) {
      MeetupFilter.joined => const EmptyState(
        icon: CupertinoIcons.checkmark_circle,
        title: '아직 신청한 자리가 없어요',
        description: '전체에서 이번 주에 열리는 모각코를 볼 수 있어요',
      ),
      MeetupFilter.hosting => EmptyState(
        icon: CupertinoIcons.plus_circle,
        title: '아직 연 모각코가 없어요',
        description: '자리를 잡고 시간을 정하면 사람이 모입니다',
        actionLabel: '모각코 만들기',
        onAction: () => context.push(AppRoute.meetupCreate),
      ),
      MeetupFilter.recurring => const EmptyState(
        icon: CupertinoIcons.repeat,
        title: '정기 모각코가 아직 없어요',
        description: '매주 같은 자리에서 열리는 모각코가 생기면 여기 모여요',
      ),
      MeetupFilter.all => EmptyState(
        icon: CupertinoIcons.person_2,
        title: '이번 주에 열리는 모각코가 없어요',
        description: '먼저 자리를 만들어 사람을 모아보세요',
        actionLabel: '모각코 만들기',
        onAction: () => context.push(AppRoute.meetupCreate),
      ),
    };
  }
}
