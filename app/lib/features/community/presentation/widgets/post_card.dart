import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/haptics.dart';
import '../../../../shared/utils/relative_time.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/post.dart';

/// 목록에 놓이는 글 한 편.
///
/// 카드로 띄우지 않고 줄로 눕힌다. 열 편이 넘게 이어지는 자리라 카드마다
/// 테두리와 그림자가 붙으면 글보다 상자가 먼저 보인다. 구분은 아래 얇은
/// 선 하나로 충분하다.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.now,
    required this.onToggleLike,
    this.isPopular = false,
    this.onTap,
  });

  final Post post;
  final DateTime now;
  final VoidCallback onToggleLike;

  /// 이번 주 반응이 많은 글인지
  final bool isPopular;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final category = post.category;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 이야기 게시판에서만 붙는다. 공지·질문 게시판은 이미 그
                // 자체로 무엇인지 분명해 한 번 더 적을 이유가 없다.
                if (category != null) ...[
                  _CategoryLabel(category: category),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (isPopular) ...[
                  const _PopularMark(),
                  const SizedBox(width: AppSpacing.sm),
                ],
                const Spacer(),
                Text(
                  relativeTime(post.createdAt, now),
                  style: context.texts.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.texts.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              post.excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                UserAvatar(
                  name: post.author,
                  imageUrl: post.authorAvatarUrl,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                // Flexible 과 Spacer 를 같이 두면 남는 폭을 반씩 나눠 갖는다.
                // 닉네임이 짧아도 그 몫이 그대로 비어 있어, 오른쪽 수치가
                // 끝에 닿지 못하고 안쪽으로 밀린다. 닉네임이 남는 폭을 다
                // 가져가게 하고 수치는 끝에 붙인다.
                Expanded(
                  child: Text(
                    post.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.labelMedium,
                  ),
                ),
                _LikeButton(
                  liked: post.isLiked,
                  count: post.likeCount,
                  onTap: onToggleLike,
                ),
                const SizedBox(width: AppSpacing.lg),
                _Metric(
                  icon: CupertinoIcons.bubble_right,
                  count: post.commentCount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 분류 표시.
///
/// 알약으로 채우면 목록마다 색 덩어리가 열 개씩 생겨 시끄럽다. 글자만
/// 브랜드 색으로 올려 무엇인지만 알린다.
class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({required this.category});

  final PostCategory category;

  @override
  Widget build(BuildContext context) {
    return Text(
      category.label,
      style: context.texts.labelSmall?.copyWith(
        color: context.colors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// 반응이 많은 글에 붙는 표시
class _PopularMark extends StatelessWidget {
  const _PopularMark();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.flame_fill, size: 12, color: colors.hot),
        const SizedBox(width: 2),
        Text(
          '인기',
          style: context.texts.labelSmall?.copyWith(
            color: colors.hot,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 누를 수 있는 좋아요.
///
/// 목록에서 바로 누를 수 있어야 한다. 글을 열고 다시 나오는 걸음이 사라진다.
///
/// 누르는 순간 하트가 한 번 부푼다. 목록 한가운데서 일어나는 일이라 색만
/// 바뀌면 눌렸는지 모르고 한 번 더 누르게 된다. 켤 때만 부풀리고 끌 때는
/// 그냥 꺼진다. 취소는 축하할 일이 아니다.
class _LikeButton extends StatefulWidget {
  const _LikeButton({
    required this.liked,
    required this.count,
    required this.onTap,
  });

  final bool liked;
  final int count;
  final VoidCallback onTap;

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 260),
    vsync: this,
  );

  /// 커졌다가 제자리로. 끝에서 살짝 넘어갔다 돌아와야 튕기는 맛이 난다.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.32,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.32,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 60,
    ),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.liked) {
      Haptics.toggle();
      _controller.forward(from: 0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = widget.liked ? colors.hot : colors.textTertiary;

    return Semantics(
      button: true,
      selected: widget.liked,
      label: '좋아요',
      child: InkWell(
        onTap: _onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          // 아이콘만으로는 손가락이 닿기에 좁다. 눌리는 자리를 넓혀 둔다.
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Icon(
                  widget.liked
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  size: AppSize.iconSm - 2,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${widget.count}',
                style: context.texts.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 누를 수 없는 수치
class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSize.iconSm - 2, color: colors.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Text('$count', style: context.texts.labelSmall),
      ],
    );
  }
}
