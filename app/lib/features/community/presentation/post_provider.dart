import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_delay.dart';
import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/providers/now_provider.dart';
import '../data/mock_posts.dart';
import '../../comment/presentation/comment_provider.dart';
import '../../comment/domain/comment.dart';
import '../../../shared/widgets/paged.dart';
import '../../safety/domain/report.dart';
import '../../safety/presentation/safety_provider.dart';
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

  /// 내가 쓴 글을 고친다.
  void edit(
    String postId, {
    required String title,
    required String body,
    PostCategory? category,
  }) {
    final now = ref.read(nowProvider);
    state = [
      for (final post in state)
        if (post.id != postId)
          post
        else
          post.edit(title: title, body: body, category: category, at: now),
    ];
  }

  /// 내가 쓴 글을 지운다.
  ///
  /// 목록에서만 뺀다. 댓글은 그대로 두면 어디에도 안 붙은 채로 남으므로
  /// 함께 지운다.
  void remove(String postId) {
    state = [
      for (final post in state)
        if (post.id != postId) post,
    ];
    ref.read(commentListProvider.notifier).removeThread(
      (target: CommentTarget.post, id: postId),
    );
  }

  /// 글쓴이 이름을 바꾼다.
  ///
  /// 서버라면 글이 사용자 id 를 들고 있어 이름만 갈아 끼우면 끝난다. 목업은
  /// 이름 문자열이 곧 글쓴이라, 프로필에서 닉네임을 고치면 내가 쓴 글이
  /// 남의 글이 되어 버린다. 그 자리를 여기서 맞춘다.
  void renameAuthor(String from, String to) {
    state = [
      for (final post in state)
        if (post.author != from) post else post.withAuthor(to),
    ];
  }

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
///
/// 차단한 사람의 글과 내가 신고한 글은 여기서 빠진다. 원본에서 지우지 않는
/// 이유는 차단을 풀면 돌아와야 하기 때문이다.
final chapterPostsProvider = Provider<List<Post>>((ref) {
  final chapter = ref.watch(currentChapterProvider);
  final blocked = ref.watch(blockedProvider);
  final reported = ref.watch(reportedKeysProvider);

  return ref
      .watch(postFeedProvider)
      .where((post) => post.chapter == chapter)
      .where((post) => !blocked.contains(post.author))
      .where((post) => !reported.contains('${ReportTarget.post.name}:${post.id}'))
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

/// 지금까지 몇 개를 받아 뒀는지.
///
/// 받아 둔 글 자체를 들고 있지 않고 개수만 센다. 목록을 통째로 들고 있으면
/// 좋아요를 누를 때마다 원본이 바뀌어 페이지가 처음으로 되돌아간다 — 읽던
/// 자리를 잃는다.
typedef PostPage = ({int loaded, bool isLoadingMore, Object? error});

class PostPaging extends Notifier<PostPage> {
  /// 한 번에 받아오는 개수.
  static const pageSize = 5;

  @override
  PostPage build() {
    // 게시판이나 분류를 바꾸면 처음부터 다시 센다. 이야기 20번째까지 보다
    // 질문으로 옮겼는데 20개가 이미 차 있으면 아래가 텅 빈 것처럼 보인다.
    ref.watch(postBoardProvider);
    ref.watch(postFilterProvider);
    return (loaded: pageSize, isLoadingMore: false, error: null);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    final total = ref.read(visiblePostsProvider).length;
    if (state.loaded >= total) return;

    state = (loaded: state.loaded, isLoadingMore: true, error: null);
    try {
      await Future<void>.delayed(mockNetworkDelay);
      state = (
        loaded: state.loaded + pageSize,
        isLoadingMore: false,
        error: null,
      );
    } catch (error) {
      // 이미 받아 둔 것은 그대로 둔다. 뒤가 실패했다고 앞까지 지우면
      // 읽던 것이 통째로 사라진다.
      state = (loaded: state.loaded, isLoadingMore: false, error: error);
    }
  }

  /// 처음부터 다시. 당겨서 새로고침할 때 함께 부른다.
  void reset() =>
      state = (loaded: pageSize, isLoadingMore: false, error: null);
}

final postPagingProvider = NotifierProvider<PostPaging, PostPage>(
  PostPaging.new,
);

/// 커뮤니티 목록에 실제로 뿌릴 것.
final pagedPostsProvider = Provider<Paged<Post>>((ref) {
  final all = ref.watch(visiblePostsProvider);
  final page = ref.watch(postPagingProvider);

  return Paged(
    items: all.take(page.loaded).toList(),
    hasMore: page.loaded < all.length,
    isLoadingMore: page.isLoadingMore,
    error: page.error,
  );
});

/// 검색 결과.
///
/// 게시판·분류를 가리지 않고 지금 지역의 글 전체에서 찾는다. 찾는 사람은
/// 그 글이 어느 게시판에 있었는지까지 기억하고 오지 않는다.
///
/// 제목·본문·글쓴이를 다 훑는다. 제목만 보면 '그 사람이 올렸던 글'을 찾을 수
/// 없고, 본문을 빼면 제목에 안 쓰인 낱말로는 못 찾는다.
final searchedPostsProvider = Provider.family<List<Post>, String>((
  ref,
  keyword,
) {
  final query = keyword.trim();
  if (query.isEmpty) return const [];

  // 영문 스택 이름을 대소문자 가리지 않고 찾게 한다. 'flutter' 로 쳐도
  // 'Flutter' 가 걸려야 한다.
  final needle = query.toLowerCase();
  bool has(String text) => text.toLowerCase().contains(needle);

  return ref
      .watch(chapterPostsProvider)
      .where(
        (post) => has(post.title) || has(post.body) || has(post.author),
      )
      .toList();
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
