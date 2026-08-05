/// 댓글이 달리는 대상.
///
/// 글에만 달리던 것을 모각코까지 넓혔다. 물어볼 게 생기는 자리는 성격이 같다 —
/// 글에는 '어떻게 하셨어요', 모각코에는 '몇 시까지 가면 되나요'.
///
/// 종류를 따로 두는 이유는 id 가 겹칠 수 있어서다. 지금은 글이 'busan-t1',
/// 모임이 'busan-1' 이라 우연히 안 겹치지만, 서버가 붙으면 각자 1부터 매기는
/// 게 보통이다.
enum CommentTarget { post, meetup, event }

/// 댓글이 달린 곳을 가리키는 열쇠.
///
/// 프로바이더 family 의 키로 쓴다. 레코드라 값이 같으면 같은 것으로 친다.
typedef CommentThread = ({CommentTarget target, String id});

/// 글이나 모임에 달린 댓글.
///
/// 커뮤니티의 실제 활동은 글보다 댓글이다. 질문 게시판은 특히 그렇다 —
/// 글은 하나인데 답이 여러 개 붙는다.
class Comment {
  const Comment({
    required this.id,
    required this.target,
    required this.targetId,
    required this.author,
    required this.body,
    required this.createdAt,
    this.editedAt,
    this.parentId,
    this.isDeleted = false,
    this.authorAvatarUrl,
    this.isMine = false,
  });

  final String id;

  /// 어디에 달린 것인지
  final CommentTarget target;
  final String targetId;

  final String author;
  final String? authorAvatarUrl;

  final String body;
  final DateTime createdAt;

  /// 마지막으로 고친 때. 한 번도 안 고쳤으면 null.
  final DateTime? editedAt;

  /// 답글이면 부모 댓글의 id. 아니면 null.
  ///
  /// 한 단계만 둔다. 답글에 답글을 달면 같은 스레드 맨 아래에 붙는다. 모바일
  /// 폭에서 3단계째는 한 줄에 몇 글자 못 들어간다.
  final String? parentId;

  /// 답글이 달린 채로 지워진 자리.
  ///
  /// 통째로 빼지 않는다. 밑에 달린 답글이 무슨 말에 대한 것인지 알 수 없게
  /// 된다. 답글이 없으면 그냥 사라지므로 이 값이 true 가 되지 않는다.
  final bool isDeleted;

  /// 내가 쓴 댓글인지.
  ///
  /// 지울 수 있는지를 가른다. 서버가 붙으면 로그인한 사람과 견줘 정해진다.
  final bool isMine;

  /// 이 댓글이 달린 곳
  CommentThread get thread => (target: target, id: targetId);

  /// 글쓴이만 바꾼 새 댓글을 만든다.
  bool get isEdited => editedAt != null;

  bool get isReply => parentId != null;

  /// 내용을 지우고 자리만 남긴다.
  Comment delete() => Comment(
    id: id,
    target: target,
    targetId: targetId,
    author: author,
    body: '',
    createdAt: createdAt,
    parentId: parentId,
    isDeleted: true,
    isMine: isMine,
  );

  /// 내용만 고친 새 댓글을 만든다.
  Comment edit(String body, DateTime at) => Comment(
    id: id,
    target: target,
    targetId: targetId,
    author: author,
    body: body,
    createdAt: createdAt,
    editedAt: at,
    parentId: parentId,
    isMine: isMine,
  );

  Comment withAuthor(String author) => Comment(
    id: id,
    target: target,
    targetId: targetId,
    author: author,
    body: body,
    createdAt: createdAt,
    editedAt: editedAt,
    parentId: parentId,
    isDeleted: isDeleted,
    isMine: isMine,
  );
}
