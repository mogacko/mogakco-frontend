import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/coming_soon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/screen_header.dart';
import '../domain/post.dart';
import 'post_provider.dart';
import 'widgets/post_card.dart';

/// 커뮤니티 탭.
///
/// 지금 보고 있는 지역의 글만 나온다. 지역은 홈 헤더에서 바꾼다.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  /// 필터 항목. 맨 앞의 null 이 '전체'다.
  static const _filters = <PostCategory?>[null, ...PostCategory.values];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = ref.watch(nowProvider);
    final posts = ref.watch(visiblePostsProvider);
    final selected = ref.watch(postFilterProvider);
    final counts = ref.watch(postCountsProvider);
    final popular = ref.watch(popularPostIdsProvider);
    final total = ref.watch(chapterPostsProvider).length;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: '커뮤니티',
              actions: [
                HeaderAction(
                  icon: CupertinoIcons.search,
                  label: '글 검색',
                  onTap: () => showComingSoon(context, '검색'),
                ),
                HeaderAction(
                  icon: CupertinoIcons.square_pencil,
                  label: '글쓰기',
                  emphasized: true,
                  onTap: () => showComingSoon(context, '글쓰기'),
                ),
              ],
            ),
            // 분류는 목록과 함께 밀려 올라가지 않게 붙여 둔다. 아래로 한참
            // 내려간 뒤에 분류를 바꾸려고 맨 위까지 되돌아가는 일이 없다.
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
            Expanded(
              child: posts.isEmpty
                  // 화면 가운데 세우되, 글자를 키운 기기에서 넘치면 스크롤한다.
                  ? Center(
                      child: SingleChildScrollView(
                        child: _Empty(category: selected),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.only(
                        bottom:
                            AppBottomNav.contentInset(context) + AppSpacing.xl,
                      ),
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
                          isPopular: popular.contains(post.id),
                          onToggleLike: () => ref
                              .read(postFeedProvider.notifier)
                              .toggleLike(post.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.category});

  /// 어떤 분류를 보다가 비었는지. null 이면 지역 전체가 비어 있다.
  final PostCategory? category;

  @override
  Widget build(BuildContext context) {
    // 분류를 좁혀서 빈 것과 아무 글도 없는 것은 다른 상황이다.
    // 앞은 필터를 풀면 되고, 뒤는 첫 글을 써야 한다.
    if (category != null) {
      return EmptyState(
        icon: CupertinoIcons.doc_text_search,
        title: '${category!.label} 글이 아직 없어요',
        description: '다른 분류를 보거나 첫 글을 남겨보세요',
      );
    }

    return EmptyState(
      icon: CupertinoIcons.bubble_left_bubble_right,
      title: '첫 글을 기다리고 있어요',
      description: '질문이든 기록이든 편하게 남겨주세요',
      actionLabel: '글쓰기',
      onAction: () => showComingSoon(context, '글쓰기'),
    );
  }
}
