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
    required this.body,
    required this.author,
    required this.createdAt,
    required this.likeCount,
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

  /// 본문 전체.
  ///
  /// 목록에서는 앞부분만 잘라 보여준다([excerpt]). 따로 요약을 두지 않는
  /// 이유는, 두 값이 어긋나면 목록에서 본 것과 열어서 본 것이 달라지기
  /// 때문이다.
  final String body;

  final String author;
  final String? authorAvatarUrl;

  final DateTime createdAt;
  final int likeCount;

  /// 내가 좋아요를 눌렀는지
  final bool isLiked;

  /// 목록에 세울 본문 앞부분.
  ///
  /// 제목만으로는 열어볼지 정하기 어렵다. 줄바꿈은 한 칸으로 눕혀야 두 줄
  /// 안에 실제 내용이 들어온다. 그대로 두면 첫 문단만 보이고 잘린다.
  String get excerpt => body.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// 좋아요를 뒤집은 새 글을 만든다.
  Post toggleLike() {
    return copyWith(
      isLiked: !isLiked,
      likeCount: isLiked ? likeCount - 1 : likeCount + 1,
    );
  }

  /// 글쓴이만 바꾼 새 글을 만든다.
  Post withAuthor(String author) => Post(
    id: id,
    chapter: chapter,
    board: board,
    category: category,
    title: title,
    body: body,
    author: author,
    authorAvatarUrl: authorAvatarUrl,
    createdAt: createdAt,
    likeCount: likeCount,
    isLiked: isLiked,
  );

  Post copyWith({bool? isLiked, int? likeCount}) {
    return Post(
      id: id,
      chapter: chapter,
      board: board,
      category: category,
      title: title,
      body: body,
      author: author,
      authorAvatarUrl: authorAvatarUrl,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
