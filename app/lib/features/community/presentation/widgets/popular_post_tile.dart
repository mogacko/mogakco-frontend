import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/relative_time.dart';
import '../../domain/post.dart';

/// 홈에 세우는 인기글 한 줄.
///
/// 커뮤니티 탭의 [PostCard] 와 달리 본문을 잘라 넣지 않는다. 홈에서는 지금
/// 무슨 이야기가 오가는지만 훑으면 되고, 읽을 마음이 들면 탭으로 넘어간다.
///
/// 순위를 앞에 세우는 건 몇 등인지가 궁금해서가 아니라, 제목 길이가 제각각인
/// 줄들이 왼쪽에서 나란히 시작하게 하는 기준이 필요해서다.
class PopularPostTile extends StatelessWidget {
  const PopularPostTile({
    super.key,
    required this.post,
    required this.rank,
    required this.now,
    required this.commentCount,
    this.onTap,
  });

  final Post post;

  /// 1부터 시작하는 순위
  final int rank;

  final DateTime now;

  /// 댓글 저장소에서 세어 넘어온다.
  final int commentCount;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$rank',
                // 순위는 제목보다 늦게 읽혀야 한다. 색을 주면 먼저 눈에 든다.
                // 굵기만으로도 왼쪽 기준선 노릇은 충분히 한다.
                style: context.texts.labelLarge?.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 작성자·시각·반응을 한 줄에 이어 붙인다. 각각을 따로 세우면
                  // 제목보다 부속 정보가 자리를 더 차지한다.
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.texts.labelSmall,
                        ),
                      ),
                      Text(
                        ' · ${relativeTime(post.createdAt, now)}',
                        style: context.texts.labelSmall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        CupertinoIcons.heart_fill,
                        size: 11,
                        color: colors.textTertiary,
                      ),
                      const SizedBox(width: 2),
                      Text('${post.likeCount}', style: context.texts.labelSmall),
                      const SizedBox(width: AppSpacing.sm - 2),
                      Icon(
                        CupertinoIcons.bubble_right_fill,
                        size: 11,
                        color: colors.textTertiary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$commentCount',
                        style: context.texts.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
