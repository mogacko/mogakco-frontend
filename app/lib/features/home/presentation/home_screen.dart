import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/section_header.dart';
import '../../community/presentation/comment_provider.dart';
import '../../community/presentation/post_detail_screen.dart';
import '../../community/presentation/post_provider.dart';
import '../../community/presentation/widgets/popular_post_tile.dart';
import '../../event/presentation/event_detail_screen.dart';
import '../../event/presentation/event_provider.dart';
import '../../event/presentation/widgets/upcoming_event_tile.dart';
import '../../meetup/presentation/meetup_provider.dart';
import '../../shell/presentation/tab_provider.dart';
import 'widgets/home_header.dart';
import 'widgets/meetup_carousel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final meetups = ref.watch(heroMeetupsProvider);
    final now = ref.watch(nowProvider);
    final isToday = ref.watch(heroIsTodayProvider);
    final events = ref.watch(upcomingEventsProvider);
    final popular = ref.watch(popularPostsProvider);
    final commentCounts = ref.watch(commentCountsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HomeHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: AppBottomNav.contentInset(context) + AppSpacing.xl,
                ),
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  // 오늘 열리는 모임이 있으면 오늘 것만 세운다. 없는 날이 더
                  // 흔해서, 그때는 가장 가까운 날로 대신한다.
                  SectionHeader(title: isToday ? '오늘의 모각코' : '다가오는 모각코'),
                  const SizedBox(height: AppSpacing.lg),
                  MeetupCarousel(
                    meetups: meetups,
                    now: now,
                    onToggleSession: (meetupId, sessionId) => ref
                        .read(meetupListProvider.notifier)
                        .toggleSession(meetupId, sessionId),
                  ),
                  // 갈 자리를 먼저 모아 두고 읽을거리는 그 아래로 둔다.
                  // 행사는 날짜가 정해져 있어 놓치면 끝이지만 글은 그렇지 않다.
                  if (events.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    SectionHeader(
                      title: '다가오는 행사',
                      actionLabel: '더보기',
                      onAction: () => ref
                          .read(currentTabProvider.notifier)
                          .select(AppTab.event),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final event in events)
                      UpcomingEventTile(
                        event: event,
                        now: now,
                        // 탭으로 보내지 않고 그 행사로 바로 들어간다. 홈에서
                        // 눌렀는데 목록으로 떨어지면 다시 찾아야 한다.
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                EventDetailScreen(eventId: event.id),
                          ),
                        ),
                      ),
                  ],
                  // 인기글이 없으면 구획째 뺀다. 빈 목록에 제목만 남으면
                  // 커뮤니티가 비어 있다는 인상이 홈까지 번진다.
                  if (popular.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    SectionHeader(
                      title: '커뮤니티 인기글',
                      actionLabel: '더보기',
                      onAction: () => ref
                          .read(currentTabProvider.notifier)
                          .select(AppTab.community),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < popular.length; i++)
                      PopularPostTile(
                        post: popular[i],
                        rank: i + 1,
                        now: now,
                        commentCount: commentCounts[popular[i].id] ?? 0,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PostDetailScreen(postId: popular[i].id),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
