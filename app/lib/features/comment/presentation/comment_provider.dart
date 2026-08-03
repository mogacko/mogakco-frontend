import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_delay.dart';
import '../../../shared/providers/now_provider.dart';
import '../../profile/data/mock_profile.dart';
import '../data/mock_comments.dart';
import '../domain/comment.dart';

/// 모든 댓글.
///
/// 대상마다 나눠 담지 않고 한 곳에 두고 걸러 쓴다. 목록 화면은 대상별 개수만
/// 필요하고 상세 화면은 한 대상의 댓글만 필요해서, 원본이 하나여야 두 쪽이
/// 어긋나지 않는다.
class CommentList extends Notifier<List<Comment>> {
  @override
  List<Comment> build() {
    final now = ref.watch(nowProvider);
    return MockComments.from(now);
  }

  /// 댓글을 단다. 빈 글은 받지 않는다.
  ///
  /// 목록 맨 뒤에 붙는다. 댓글은 대화라 위에서 아래로 읽는 게 자연스럽다.
  void add(CommentThread thread, String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    state = [
      ...state,
      Comment(
        // 서버가 붙으면 서버가 정한 id 가 온다. 그때까지는 겹치지 않을 만큼만.
        id: '$_localPrefix${state.length}-${trimmed.hashCode}',
        target: thread.target,
        targetId: thread.id,
        author: MockProfile.nickname,
        body: trimmed,
        createdAt: ref.read(nowProvider),
        isMine: true,
      ),
    ];
  }

  /// 내가 쓴 댓글만 지운다.
  void remove(String commentId) {
    state = [
      for (final comment in state)
        if (!(comment.id == commentId && comment.isMine)) comment,
    ];
  }

  /// 내가 단 댓글의 이름을 바꾼다.
  ///
  /// [isMine] 으로만 가른다. 목업에 나와 같은 이름을 쓰는 사람이 있어도 그건
  /// 내 댓글이 아니다.
  void renameAuthor(String nickname) {
    state = [
      for (final comment in state)
        if (!comment.isMine) comment else comment.withAuthor(nickname),
    ];
  }

  /// 당겨서 새로고침.
  ///
  /// 서버가 붙으면 여기서 다시 받아온다. 그때는 내가 단 댓글도 응답에 실려
  /// 오므로 아래 옮겨 담기는 지운다.
  ///
  /// 지금 목업을 다시 읽으면 두 가지가 어긋난다. 방금 단 댓글이 사라지고,
  /// 지웠던 댓글이 되살아난다. 새로고침이 되돌리기처럼 보이는 자리다.
  Future<void> refresh() async {
    // 목업에 없던 것 = 내가 여기서 단 것
    final mine = state.where((comment) => comment.id.startsWith(_localPrefix));
    final kept = {for (final comment in state) comment.id};

    await Future<void>.delayed(mockNetworkDelay);

    state = [
      for (final comment in MockComments.from(ref.read(nowProvider)))
        if (kept.contains(comment.id)) comment,
      ...mine,
    ];
  }

  /// 서버가 아직 id 를 주지 못하는 동안 쓰는 앞머리.
  static const _localPrefix = 'local-';
}

final commentListProvider = NotifierProvider<CommentList, List<Comment>>(
  CommentList.new,
);

/// 한 대상의 댓글. 단 순서대로.
final commentsOfProvider = Provider.family<List<Comment>, CommentThread>((
  ref,
  thread,
) {
  return ref
      .watch(commentListProvider)
      .where((comment) => comment.thread == thread)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
});

/// 글별 댓글 수.
///
/// 목록에 찍히는 값이다. 글에 개수를 따로 들고 있으면 댓글을 달 때마다 두
/// 곳을 맞춰야 하고, 한 번 어긋나면 목록과 상세가 다른 숫자를 말한다.
final postCommentCountsProvider = Provider<Map<String, int>>((ref) {
  final counts = <String, int>{};
  for (final comment in ref.watch(commentListProvider)) {
    if (comment.target != CommentTarget.post) continue;
    counts[comment.targetId] = (counts[comment.targetId] ?? 0) + 1;
  }
  return counts;
});
