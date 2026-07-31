import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/utils/relative_time.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../domain/post.dart';
import '../../comment/domain/comment.dart';
import '../../comment/presentation/comment_provider.dart';
import '../../comment/presentation/widgets/comment_section.dart';
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
          comments: comments,
          now: now,
          onDelete: (comment) =>
              ref.read(commentListProvider.notifier).remove(comment.id),
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
                      relativeTime(post.createdAt, now),
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
