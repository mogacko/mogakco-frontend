import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/utils/relative_time.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/navigation.dart';
import '../../../shared/widgets/owner_menu.dart';
import '../../member/presentation/member_provider.dart';
import '../../safety/domain/report.dart';
import '../../safety/presentation/widgets/safety_menu.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../domain/post.dart';
import '../../comment/domain/comment.dart';
import '../../comment/presentation/comment_provider.dart';
import '../../comment/presentation/widgets/comment_section.dart';
import '../../comment/presentation/widgets/edit_comment_sheet.dart';
import 'post_provider.dart';

/// 글 하나.
///
/// 글 객체가 아니라 id 를 받는다. 객체를 넘기면 좋아요를 누르거나 댓글을 단
/// 뒤에도 화면이 들어올 때의 값을 그대로 들고 있다.
class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  CommentThread _threadOf(String id) => (target: CommentTarget.post, id: id);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final post = ref
        .watch(postFeedProvider)
        .where((post) => post.id == postId)
        .firstOrNull;

    if (post == null) {
      // 서버가 붙으면 지워진 글을 열었을 때 여기로 온다.
      return const DetailScaffold(
        children: [
          EmptyState(
            icon: CupertinoIcons.doc_text_search,
            title: '글을 찾을 수 없어요',
            description: '지워졌거나 옮겨진 글일 수 있어요',
          ),
        ],
      );
    }

    final comments = ref.watch(commentsOfProvider(_threadOf(postId)));

    return DetailScaffold(
      title: post.board.label,
      actions: [
        // 내 글에는 신고가 아니라 고치기·삭제가 붙는다. 같은 '⋯' 자리를 쓴다.
        if (post.author == ref.watch(myIdProvider))
          OwnerMenuButton(onTap: () => _ownerMenu(context, ref, post))
        else
          SafetyMenuButton(
            target: ReportTarget.post,
            targetId: post.id,
            authorId: post.author,
          ),
      ],
      // 본체와 댓글을 함께 다시 읽는다. 정원만 바뀌고 댓글은 그대로면
      // 새로고침이 반쯤 된 것처럼 보인다.
      onRefresh: () => Future.wait([
        ref.read(postFeedProvider.notifier).refresh(),
        ref.read(commentListProvider.notifier).refresh(),
      ]),
      bottomAction: CommentField(
        onSubmit: (body) {
          Haptics.toggle();
          ref.read(commentListProvider.notifier).add(_threadOf(postId), body);
        },
      ),
      children: [
        _Head(post: post, now: now),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Text(post.body, style: context.texts.bodyLarge),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: _LikeBar(post: post),
        ),
        const SizedBox(height: AppSpacing.xl),
        Divider(height: 1, color: context.colors.border),
        const SizedBox(height: AppSpacing.xl),
        CommentSection(
          nodes: ref.watch(commentTreeProvider((target: CommentTarget.post, id: post.id))),
          count: comments.length,
          now: now,
          onDelete: (comment) =>
              ref.read(commentListProvider.notifier).remove(comment.id),
          onEdit: (comment) => _editComment(context, ref, comment),
          onReply: (parent, body) => ref
              .read(commentListProvider.notifier)
              .add(parent.thread, body, parentId: parent.id),
        ),
      ],
    );
  }
}

/// 분류·제목·작성자
class _Head extends StatelessWidget {
  const _Head({required this.post, required this.now});

  final Post post;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final category = post.category;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 게시판은 상단 바가 이미 말하고 있어 분류만 남긴다.
          if (category != null) ...[
            Text(
              category.label,
              style: context.texts.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(post.title, style: context.texts.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              UserAvatar(
                name: post.author,
                imageUrl: post.authorAvatarUrl,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author,
                      style: context.texts.labelMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      // 고친 글에는 표를 붙인다. 댓글이 달린 뒤에 본문이 바뀌면
                      // 대화가 어긋나 보이는데, 표가 없으면 읽는 쪽에서 그
                      // 이유를 알 길이 없다.
                      post.isEdited
                          ? '${relativeTime(post.createdAt, now)} · 수정됨'
                          : relativeTime(post.createdAt, now),
                      style: context.texts.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 본문 끝의 좋아요.
///
/// 목록에서는 작은 아이콘이지만 여기서는 다 읽고 누르는 자리라 넓게 둔다.
class _LikeBar extends ConsumerWidget {
  const _LikeBar({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final liked = post.isLiked;

    return Align(
      alignment: Alignment.center,
      child: Semantics(
        button: true,
        selected: liked,
        child: Material(
          color: liked ? colors.hot.withValues(alpha: 0.10) : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            side: BorderSide(color: liked ? colors.hot : colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (!liked) Haptics.toggle();
              ref.read(postFeedProvider.notifier).toggleLike(post.id);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    liked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    size: AppSize.iconSm,
                    color: liked ? colors.hot : colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${post.likeCount}',
                    style: context.texts.labelMedium?.copyWith(
                      color: liked ? colors.hot : colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 내 글의 '⋯'에서 고르는 일.
Future<void> _ownerMenu(BuildContext context, WidgetRef ref, Post post) async {
  final commentCount = ref
      .read(commentsOfProvider((target: CommentTarget.post, id: post.id)))
      .length;

  final action = await showOwnerSheet(
    context,
    what: '글',
    deleteTitle: '이 글을 삭제할까요?',
    // 달린 댓글이 함께 사라진다는 걸 지우기 전에 알린다. 지우고 나서 알면
    // 되돌릴 방법이 없다.
    deleteDescription: commentCount > 0
        ? '달린 댓글 $commentCount개도 함께 사라지고 되돌릴 수 없어요.'
        : '되돌릴 수 없어요.',
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case OwnerAction.edit:
      context.push(AppRoute.postEdit(post.id));
    case OwnerAction.delete:
      // 화면을 먼저 뺀다. 글이 사라진 자리에 서 있으면 '찾을 수 없어요'가 뜬다.
      goBack(context);
      ref.read(postFeedProvider.notifier).remove(post.id);
  }
}

/// 댓글을 고친다. 화면을 새로 열지 않고 시트에서 받는다.
Future<void> _editComment(
  BuildContext context,
  WidgetRef ref,
  Comment comment,
) async {
  final body = await showEditCommentSheet(context, initial: comment.body);
  if (body == null) return;
  ref.read(commentListProvider.notifier).edit(comment.id, body);
}
