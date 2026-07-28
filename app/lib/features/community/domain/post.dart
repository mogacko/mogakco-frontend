import '../../../shared/domain/chapter.dart';

/// 커뮤니티 글 한 편.
class Post {
  const Post({
    required this.id,
    required this.chapter,
    required this.title,
    required this.author,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    this.authorAvatarUrl,
  });

  final String id;

  /// 글이 속한 지역. 커뮤니티는 지부별로 나뉜다.
  final Chapter chapter;

  final String title;
  final String author;
  final String? authorAvatarUrl;

  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  /// 얼마나 반응을 얻었는지.
  ///
  /// 댓글은 좋아요보다 품이 드는 반응이라 두 배로 센다. 진짜 인기 지표는
  /// 조회수 대비 반응률이겠지만 그건 서버 집계가 있어야 한다.
  int get engagement => likeCount + commentCount * 2;
}
