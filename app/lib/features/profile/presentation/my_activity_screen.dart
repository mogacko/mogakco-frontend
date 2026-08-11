import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../comment/presentation/comment_provider.dart';
import '../../community/presentation/post_provider.dart';
import '../../community/presentation/widgets/post_card.dart';
import '../../event/presentation/event_provider.dart';
import '../../event/presentation/widgets/event_card.dart';
import '../../meetup/presentation/meetup_provider.dart';
import '../../meetup/presentation/widgets/meetup_list_card.dart';
import 'profile_provider.dart';

/// 내 정보의 숫자를 눌러서 들어오는 자리.
enum MyActivityKind {
  meetups('참여 중인 모각코'),
  events('신청한 행사'),
  posts('작성한 글');

  const MyActivityKind(this.label);

  final String label;

  /// 주소에 들어가는 이름. 새로고침해도 어느 것을 보고 있었는지 남는다.
  static MyActivityKind parse(String? value) {
    for (final kind in values) {
      if (kind.name == value) return kind;
    }
    return meetups;
  }
}

/// 내 활동.
///
/// 셋을 한 화면에 두고 위에서 갈아 끼운다. 화면을 셋으로 나누면 모각코를 보다
/// 행사를 보려고 내 정보까지 되돌아가야 한다 — 세는 대상만 다를 뿐 '내가 한
/// 것'이라는 점에서 같은 자리다.
class MyActivityScreen extends ConsumerStatefulWidget {
  const MyActivityScreen({super.key, required this.kind});

  final MyActivityKind kind;

  @override
  ConsumerState<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends ConsumerState<MyActivityScreen> {
  late MyActivityKind _kind = widget.kind;

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(nowProvider);

    return DetailScaffold(
      title: '내 활동',
      children: [
        FilterBar<MyActivityKind>(
          options: MyActivityKind.values,
          selected: _kind,
          labelOf: (kind) => kind.label,
          countOf: (kind) => switch (kind) {
            MyActivityKind.meetups => ref.watch(myMeetupsProvider).length,
            MyActivityKind.events => ref.watch(myAppliedEventsProvider).length,
            MyActivityKind.posts => ref.watch(myPostsProvider).length,
          },
          onSelect: (kind) => setState(() => _kind = kind),
        ),
        const SizedBox(height: AppSpacing.md),
        switch (_kind) {
          MyActivityKind.meetups => _Meetups(now: now),
          MyActivityKind.events => _Events(now: now),
          MyActivityKind.posts => _Posts(now: now),
        },
      ],
    );
  }
}

class _Meetups extends ConsumerWidget {
  const _Meetups({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetups = ref.watch(myMeetupsProvider);

    if (meetups.isEmpty) {
      return const _Empty(
        icon: CupertinoIcons.person_2,
        title: '참여 중인 모각코가 없어요',
        description: '모각코 탭에서 이번 주에 갈 자리를 골라보세요',
      );
    }

    return Column(
      children: [
        for (final meetup in meetups) ...[
          MeetupListCard(
            meetup: meetup,
            now: now,
            // 지역을 걸러내지 않는 목록이라 어디 자리인지 붙여준다.
            showChapter: true,
            onTap: () => context.push(AppRoute.meetup(meetup.id)),
            onToggleSession: (sessionId) => ref
                .read(meetupListProvider.notifier)
                .toggleSession(meetup.id, sessionId),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _Events extends ConsumerWidget {
  const _Events({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(myAppliedEventsProvider);

    if (events.isEmpty) {
      return const _Empty(
        icon: CupertinoIcons.ticket,
        title: '신청한 행사가 없어요',
        description: '행사 탭에서 열리는 자리를 둘러보세요',
      );
    }

    return Column(
      children: [
        for (final event in events) ...[
          EventCard(
            event: event,
            now: now,
            showChapter: true,
            onTap: () => context.push(AppRoute.event(event.id)),
            onToggleApply: () =>
                ref.read(eventListProvider.notifier).toggleApply(event.id),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _Posts extends ConsumerWidget {
  const _Posts({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(myPostsProvider);
    final commentCounts = ref.watch(postCommentCountsProvider);

    if (posts.isEmpty) {
      return const _Empty(
        icon: CupertinoIcons.square_pencil,
        title: '작성한 글이 없어요',
        description: '커뮤니티에 첫 글을 남겨보세요',
      );
    }

    return Column(
      children: [
        for (final post in posts)
          PostCard(
            post: post,
            now: now,
            commentCount: commentCounts[post.id] ?? 0,
            // 게시판을 넘나드는 목록이라 어디에 쓴 글인지 붙여준다.
            showBoard: true,
            onToggleLike: () =>
                ref.read(postFeedProvider.notifier).toggleLike(post.id),
            onTap: () => context.push(AppRoute.post(post.id)),
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.huge),
      child: EmptyState(icon: icon, title: title, description: description),
    );
  }
}
