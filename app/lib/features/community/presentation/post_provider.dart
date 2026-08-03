import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_delay.dart';
import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/providers/now_provider.dart';
import '../data/mock_posts.dart';
import '../../comment/presentation/comment_provider.dart';
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

  /// 새 글을 올린다.
  ///
  /// 맨 앞에 꽂는다. 목록이 최신순이라 방금 쓴 글이 위에 오는 게 규칙과 맞고,
  /// 아래로 내려가 찾게 두면 올라간 게 맞는지 확인할 길이 없다.
  void add(Post post) => state = [post, ...state];

  /// 당겨서 새로고침.
  ///
  /// 서버가 붙으면 여기서 다시 받아온다. 그때는 내가 누른 좋아요도 응답에
  /// 실려 오므로 아래 옮겨 담기는 지운다. 지금은 목업을 다시 읽으면 내가
  /// 눌러 둔 것이 사라져서, 새로고침이 되돌리기처럼 보인다.
  Future<void> refresh() async {
    // 목업에 없던 것 = 여기서 내가 쓴 것. 서버가 붙으면 응답에 실려 온다.
    final mine = state
        .where((post) => post.id.startsWith(localPrefix))
        .toList();
    final liked = {
      for (final post in state)
        if (post.isLiked) post.id,
    };

    await Future<void>.delayed(mockNetworkDelay);

    state =
        MockPosts.from(ref.read(nowProvider)).map((post) {
          // 목업에도 미리 눌러 둔 글이 있어서, 무조건 뒤집으면 어긋난다.
          // 내 상태와 다를 때만 맞춘다.
          final byMe = liked.contains(post.id);
          return post.isLiked == byMe ? post : post.toggleLike();
        }).toList()
          ..addAll(mine)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 서버가 아직 id 를 주지 못하는 동안 쓰는 앞머리.
  static const localPrefix = 'local-';
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

/// 지금 보고 있는 게시판. 상단 제목에서 바꾼다.
class PostBoardSelection extends Notifier<PostBoard> {
  @override
  PostBoard build() => PostBoard.talk;

  void select(PostBoard board) => state = board;
}

final postBoardProvider = NotifierProvider<PostBoardSelection, PostBoard>(
  PostBoardSelection.new,
);

/// 지금 게시판의 글
final boardPostsProvider = Provider<List<Post>>((ref) {
  final board = ref.watch(postBoardProvider);
  return ref
      .watch(chapterPostsProvider)
      .where((post) => post.board == board)
      .toList();
});

/// 이야기 게시판에서 고른 분류. null 이면 전체.
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
  final board = ref.watch(postBoardProvider);
  final posts = ref.watch(boardPostsProvider);

  // 공지와 질문은 분류가 없다. 필터를 걸 것도 없다.
  if (!board.hasCategories) return posts;

  final category = ref.watch(postFilterProvider);
  if (category == null) return posts;
  return posts.where((post) => post.category == category).toList();
});

/// 이야기 게시판의 분류별 글 개수.
/// 필터 알약에 붙여 빈 분류를 눌러보게 두지 않는다.
final postCountsProvider = Provider<Map<PostCategory, int>>((ref) {
  final counts = <PostCategory, int>{};
  for (final post in ref.watch(boardPostsProvider)) {
    final category = post.category;
    if (category == null) continue;
    counts[category] = (counts[category] ?? 0) + 1;
  }
  return counts;
});

/// 인기글로 셀 최소 반응 수.
///
/// 이 선을 넘지 못하면 목록에서 가장 높아도 인기글이 아니다. 갓 만든 지부는
/// 반응 두어 개짜리 글이 1등이 되는데, 그걸 '인기'라 부르면 말이 헐거워진다.
const _popularThreshold = 20;

/// 얼마나 반응을 얻었는지.
///
/// 댓글은 좋아요보다 품이 드는 반응이라 두 배로 센다. 진짜 인기 지표는
/// 조회수 대비 반응률이겠지만 그건 서버 집계가 있어야 한다.
int _engagement(Post post, Map<String, int> commentCounts) =>
    post.likeCount + (commentCounts[post.id] ?? 0) * 2;

/// 홈에 세울 인기글.
///
/// 최근 것 위주로 본다. 지난달 글이 계속 1등이면 커뮤니티가 멈춰 보인다.
///
/// 공지는 뺀다. 운영진이 올린 글이라 반응이 많이 붙기 마련이라 그대로 두면
/// 인기글 자리를 공지가 차지한다. 그건 인기가 아니라 공지다.
final popularPostsProvider = Provider<List<Post>>((ref) {
  final now = ref.watch(nowProvider);
  final commentCounts = ref.watch(postCommentCountsProvider);

  final recent =
      ref
          .watch(chapterPostsProvider)
          .where((post) => post.board != PostBoard.notice)
          .where((post) => now.difference(post.createdAt).inDays < 7)
          .where((post) => _engagement(post, commentCounts) >= _popularThreshold)
          .toList()
        ..sort(
          (a, b) => _engagement(
            b,
            commentCounts,
          ).compareTo(_engagement(a, commentCounts)),
        );

  return recent.take(3).toList();
});

/// 인기글로 뽑힌 글의 id.
///
/// 커뮤니티 탭에서도 같은 글에 표시를 붙이려면 기준이 한 곳이어야 한다.
final popularPostIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(popularPostsProvider).map((post) => post.id).toSet();
});
