import '../../../shared/domain/chapter.dart';

/// 글의 분류.
///
/// 커뮤니티에 올라오는 글은 성격이 꽤 다르다. 답을 기다리는 질문과 그냥
/// 남기는 기록을 한 줄에 섞어 놓으면 둘 다 묻힌다.
enum PostCategory {
  free('자유'),
  question('질문'),
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
    required this.category,
    required this.title,
    required this.excerpt,
    required this.author,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    this.authorAvatarUrl,
    this.isLiked = false,
  });

  final String id;

  /// 글이 속한 지역. 커뮤니티는 지부별로 나뉜다.
  final Chapter chapter;

  final PostCategory category;

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
