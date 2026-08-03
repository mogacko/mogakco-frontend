import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/coming_soon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/title_menu.dart';
import '../domain/post.dart';
import '../../comment/presentation/comment_provider.dart';
import 'post_provider.dart';
import 'widgets/post_card.dart';

/// 커뮤니티 탭.
///
/// 게시판은 상단 제목에서 바꾸고, 이야기 게시판 안의 분류는 그 아래 필터에서
/// 좁힌다. 둘을 같은 줄에 놓으면 무엇이 무엇을 좁히는지 흐려진다.
///
/// 지금 보고 있는 지역의 글만 나온다. 지역은 홈 헤더에서 바꾼다.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  /// 분류 필터 항목. 맨 앞의 null 이 '전체'다.
  static const _filters = <PostCategory?>[null, ...PostCategory.values];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = ref.watch(nowProvider);
    final board = ref.watch(postBoardProvider);
    final posts = ref.watch(visiblePostsProvider);
    final selected = ref.watch(postFilterProvider);
    final counts = ref.watch(postCountsProvider);
    final popular = ref.watch(popularPostIdsProvider);
    final total = ref.watch(boardPostsProvider).length;
    final commentCounts = ref.watch(postCommentCountsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader.custom(
              titleWidget: TitleMenu<PostBoard>(
                current: board,
                options: PostBoard.values,
                labelOf: (board) => board.label,
                tooltip: '게시판 바꾸기',
                onSelected: (board) =>
                    ref.read(postBoardProvider.notifier).select(board),
              ),
              actions: [
                HeaderAction(
                  icon: CupertinoIcons.search,
                  label: '글 검색',
                  onTap: () => showComingSoon(context, '검색'),
                ),
                // 공지는 운영진만 올린다. 쓸 수 없는 자리에 버튼을 두면
                // 눌러보고 나서야 안 된다는 걸 알게 된다.
                if (board.isWritable)
                  HeaderAction(
                    icon: CupertinoIcons.square_pencil,
                    label: '글쓰기',
                    emphasized: true,
                    onTap: () => context.push(AppRoute.postWrite(board)),
                  ),
              ],
            ),
            // 공지와 질문에는 분류가 없다. 빈 필터 줄을 남기지 않는다.
            if (board.hasCategories) ...[
              FilterBar<PostCategory?>(
                options: _filters,
                selected: selected,
                labelOf: (category) => category?.label ?? '전체',
                countOf: (category) =>
                    category == null ? total : (counts[category] ?? 0),
                onSelect: (category) =>
                    ref.read(postFilterProvider.notifier).select(category),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            // 글은 카드로 쪼개지 않는다. 열 편 넘게 이어지는 자리라 카드마다
            // 테두리가 붙으면 글보다 상자가 먼저 보인다. 대신 목록 전체를
            // 흰 면 하나에 올려 다른 탭의 카드와 같은 높이에 둔다. 글자가
            // 놓이는 바탕이 바뀌지 않아 길게 읽어도 눈이 덜 흔들린다.
            Expanded(
              child: ColoredBox(
                color: colors.surface,
                child: PullToRefresh(
                  onRefresh: () =>
                      ref.read(postFeedProvider.notifier).refresh(),
                  slivers: [
                    if (posts.isEmpty)
                      // 남는 자리를 다 차지해 가운데 세운다. 글자를 키운
                      // 기기에서 넘치면 그때는 스크롤된다.
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: _Empty(board: board, category: selected),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom:
                              AppBottomNav.contentInset(context) +
                              AppSpacing.xl,
                        ),
                        sliver: SliverList.separated(
                          itemCount: posts.length,
                          separatorBuilder: (context, _) => Divider(
                            height: 1,
                            // 선을 화면 끝까지 긋지 않고 본문 여백에 맞춘다.
                            indent: AppSpacing.screenHorizontal,
                            endIndent: AppSpacing.screenHorizontal,
                            color: colors.border,
                          ),
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return PostCard(
                              post: post,
                              now: now,
                              commentCount: commentCounts[post.id] ?? 0,
                              isPopular: popular.contains(post.id),
                              onToggleLike: () => ref
                                  .read(postFeedProvider.notifier)
                                  .toggleLike(post.id),
                              onTap: () =>
                                  context.push(AppRoute.post(post.id)),
                            );
                          },
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
  const _Empty({required this.board, required this.category});

  final PostBoard board;

  /// 이야기 게시판에서 어떤 분류를 보다가 비었는지. null 이면 게시판이 비었다.
  final PostCategory? category;

  @override
  Widget build(BuildContext context) {
    // 분류를 좁혀서 빈 것과 게시판 자체가 빈 것은 다른 상황이다.
    // 앞은 필터를 풀면 되고, 뒤는 첫 글을 써야 한다.
    if (category != null) {
      return EmptyState(
        icon: CupertinoIcons.doc_text_search,
        title: '${category!.label} 글이 아직 없어요',
        description: '다른 분류를 보거나 첫 글을 남겨보세요',
      );
    }

    return switch (board) {
      // 공지는 운영진이 올린다. 사용자가 지금 할 수 있는 일이 없다.
      PostBoard.notice => const EmptyState(
        icon: CupertinoIcons.speaker_2,
        title: '아직 올라온 공지가 없어요',
        description: '알려드릴 일이 생기면 여기에 적어둘게요',
      ),
      PostBoard.question => EmptyState(
        icon: CupertinoIcons.question_circle,
        title: '첫 질문을 기다리고 있어요',
        description: '막히는 부분이 있으면 편하게 물어보세요',
        actionLabel: '질문하기',
        onAction: () => context.push(AppRoute.postWrite(PostBoard.question)),
      ),
      PostBoard.talk => EmptyState(
        icon: CupertinoIcons.bubble_left_bubble_right,
        title: '첫 글을 기다리고 있어요',
        description: '후기든 기록이든 편하게 남겨주세요',
        actionLabel: '글쓰기',
        onAction: () => context.push(AppRoute.postWrite(PostBoard.talk)),
      ),
    };
  }
}
