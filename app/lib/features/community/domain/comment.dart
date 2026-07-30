/// 글에 달린 댓글.
///
/// 커뮤니티의 실제 활동은 글보다 댓글이다. 질문 게시판은 특히 그렇다 —
/// 글은 하나인데 답이 여러 개 붙는다.
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.body,
    required this.createdAt,
    this.authorAvatarUrl,
    this.isMine = false,
  });

  final String id;

  /// 어느 글에 달린 것인지
  final String postId;

  final String author;
  final String? authorAvatarUrl;

  final String body;
  final DateTime createdAt;

  /// 내가 쓴 댓글인지.
  ///
  /// 지울 수 있는지를 가른다. 서버가 붙으면 로그인한 사람과 견줘 정해진다.
  final bool isMine;
}
