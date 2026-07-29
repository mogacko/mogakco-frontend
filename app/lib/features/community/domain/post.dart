import '../../../shared/domain/chapter.dart';

/// 커뮤니티 게시판.
///
/// 성격이 다른 글을 한 줄에 섞으면 셋 다 묻힌다. 공지는 놓치면 안 되고,
/// 질문은 답을 기다리며, 이야기는 그냥 읽는다. 읽는 마음가짐이 달라서
/// 분류가 아니라 게시판으로 나눈다.
enum PostBoard {
  notice('공지'),
  question('질문'),
  talk('이야기');

  const PostBoard(this.label);

  final String label;

  /// 글쓴이가 고르는 분류가 있는 게시판인지.
  ///
  /// 공지와 질문은 그 자체로 무엇인지 분명해 더 쪼갤 이유가 없다.
  bool get hasCategories => this == PostBoard.talk;

  /// 아무나 쓸 수 있는 게시판인지. 공지는 운영진만 올린다.
  bool get isWritable => this != PostBoard.notice;
}

/// 이야기 게시판 안의 분류.
///
/// 질문은 여기 없다. 게시판으로 올라갔다.
enum PostCategory {
  free('자유'),
  retrospective('회고'),
  recruit('모집');

  const PostCategory(this.label);

  final String label;
}

/// 커뮤니티 글 한 편.
class Post {
  const Post({
    required this.id,
    required this.chapter,
    required this.board,
    required this.title,
    required this.excerpt,
    required this.author,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    this.category,
    this.authorAvatarUrl,
    this.isLiked = false,
  });

  final String id;

  /// 글이 속한 지역. 커뮤니티는 지부별로 나뉜다.
  final Chapter chapter;

  final PostBoard board;

  /// 이야기 게시판에서만 붙는다. 다른 게시판에서는 null.
  final PostCategory? category;

  final String title;

  /// 본문 앞부분. 목록에서 제목만으로는 열어볼지 정하기 어렵다.
  final String excerpt;

  final String author;
  final String? authorAvatarUrl;

  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  /// 내가 좋아요를 눌렀는지
  final bool isLiked;

  /// 얼마나 반응을 얻었는지.
  ///
  /// 댓글은 좋아요보다 품이 드는 반응이라 두 배로 센다. 진짜 인기 지표는
  /// 조회수 대비 반응률이겠지만 그건 서버 집계가 있어야 한다.
  int get engagement => likeCount + commentCount * 2;

  /// 좋아요를 뒤집은 새 글을 만든다.
  Post toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likeCount: isLiked ? likeCount - 1 : likeCount + 1,
    );
  }

  Post copyWith({bool? isLiked, int? likeCount}) {
    return Post(
      id: id,
      chapter: chapter,
      board: board,
      category: category,
      title: title,
      excerpt: excerpt,
      author: author,
      authorAvatarUrl: authorAvatarUrl,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
