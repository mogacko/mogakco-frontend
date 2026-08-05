import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import 'post_provider.dart';
import 'post_write_screen.dart';

/// 글 고치기.
///
/// 게시판은 주소에 없다. 원래 글의 것을 그대로 쓰기 때문이다 — 질문으로 올린
/// 글이 이야기로 옮겨 가면 답을 기다리던 사람이 그 글을 다시 찾을 수 없다.
/// 그래서 글을 먼저 찾아 게시판을 읽고 쓰기 화면에 넘긴다.
class PostEditScreen extends ConsumerWidget {
  const PostEditScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref
        .watch(postFeedProvider)
        .where((post) => post.id == postId)
        .firstOrNull;

    if (post == null) {
      return const DetailScaffold(
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.huge),
            child: EmptyState(
              icon: CupertinoIcons.doc_text,
              title: '글을 찾을 수 없어요',
              description: '지워졌거나 잘못된 주소일 수 있어요',
            ),
          ),
        ],
      );
    }

    return PostWriteScreen(board: post.board, postId: postId);
  }
}
