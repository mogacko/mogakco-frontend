import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/providers/now_provider.dart';
import '../data/mock_posts.dart';
import '../domain/post.dart';

/// 커뮤니티 글 목록과 좋아요 상태.
///
/// 서버가 붙기 전이라 목업을 메모리에 두고 좋아요만 반영한다.
class PostFeed extends Notifier<List<Post>> {
  @override
  List<Post> build() {
    final now = ref.watch(nowProvider);

    // 순서는 여기서 한 번만 정한다. 볼 때마다 다시 정렬하면 좋아요를 누르는
    // 순간 글이 자리를 옮겨 읽던 곳을 잃는다.
    return MockPosts.from(now)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void toggleLike(String postId) {
    state = [
      for (final post in state)
        if (post.id != postId) post else post.toggleLike(),
    ];
  }
}

final postFeedProvider = NotifierProvider<PostFeed, List<Post>>(PostFeed.new);

/// 지금 보고 있는 지역의 글. 순서는 [PostFeed] 가 정한 대로 둔다.
final chapterPostsProvider = Provider<List<Post>>((ref) {
  final chapter = ref.watch(currentChapterProvider);
  return ref
      .watch(postFeedProvider)
      .where((post) => post.chapter == chapter)
      .toList();
});

/// 고른 분류. null 이면 전체.
class PostFilter extends Notifier<PostCategory?> {
  @override
  PostCategory? build() => null;

  void select(PostCategory? category) => state = category;
}

final postFilterProvider = NotifierProvider<PostFilter, PostCategory?>(
  PostFilter.new,
);

/// 커뮤니티 탭에 뿌릴 글
final visiblePostsProvider = Provider<List<Post>>((ref) {
  final category = ref.watch(postFilterProvider);
  final posts = ref.watch(chapterPostsProvider);

  if (category == null) return posts;
  return posts.where((post) => post.category == category).toList();
});

/// 분류별 글 개수. 필터 알약에 붙여 빈 분류를 눌러보게 두지 않는다.
final postCountsProvider = Provider<Map<PostCategory, int>>((ref) {
  final counts = <PostCategory, int>{};
  for (final post in ref.watch(chapterPostsProvider)) {
    counts[post.category] = (counts[post.category] ?? 0) + 1;
  }
  return counts;
});

/// 인기글로 셀 최소 반응 수.
///
/// 이 선을 넘지 못하면 목록에서 가장 높아도 인기글이 아니다. 갓 만든 지부는
/// 반응 두어 개짜리 글이 1등이 되는데, 그걸 '인기'라 부르면 말이 헐거워진다.
const _popularThreshold = 20;

/// 홈에 세울 인기글.
///
/// 최근 것 위주로 본다. 지난달 글이 계속 1등이면 커뮤니티가 멈춰 보인다.
final popularPostsProvider = Provider<List<Post>>((ref) {
  final now = ref.watch(nowProvider);

  final recent =
      ref
          .watch(chapterPostsProvider)
          .where((post) => now.difference(post.createdAt).inDays < 7)
          .where((post) => post.engagement >= _popularThreshold)
          .toList()
        ..sort((a, b) => b.engagement.compareTo(a.engagement));

  return recent.take(3).toList();
});

/// 인기글로 뽑힌 글의 id.
///
/// 커뮤니티 탭에서도 같은 글에 표시를 붙이려면 기준이 한 곳이어야 한다.
final popularPostIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(popularPostsProvider).map((post) => post.id).toSet();
});
