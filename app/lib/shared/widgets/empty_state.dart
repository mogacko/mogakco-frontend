import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 보여줄 것이 없을 때의 화면.
///
/// 목록이 빈 건 대부분 오류가 아니라 아직 시작하지 않은 상태다. 그래서 빈
/// 자리를 그대로 두거나 회색 글자 한 줄로 넘기지 않고, 왜 비었는지와 무엇을
/// 하면 채워지는지를 같이 둔다.
///
/// 아이콘은 옅은 원 안에 넣어 글자보다 먼저 눈에 들되 화면을 지배하지는
/// 않게 한다.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;

  /// 왜 비었는지 한 줄. 제목만으로 충분하면 비워도 된다.
  final String? description;

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final description = this.description;
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.huge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: colors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.texts.titleLarge,
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            // 화면 폭을 다 쓰면 빈 화면에서 버튼만 커 보인다. 글자만큼만 쓴다.
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
              ),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
