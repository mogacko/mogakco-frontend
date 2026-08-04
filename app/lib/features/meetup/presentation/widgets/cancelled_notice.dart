import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/relative_time.dart';
import '../../domain/meetup.dart';

/// 접힌 모임에 붙는 안내.
///
/// 사유를 크게 적는다. 오기로 했던 사람이 확인하러 들어오는 자리라, '취소됨'
/// 세 글자만 있으면 왜 안 열리는지 물어볼 데를 또 찾아야 한다.
class CancelledNotice extends StatelessWidget {
  const CancelledNotice({
    super.key,
    required this.cancellation,
    required this.now,
  });

  final Cancellation cancellation;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        // 위험색 면을 통째로 깔지 않는다. 접힌 것은 사고가 아니라 사정이고,
        // 화면 절반이 빨개지면 읽기 전에 놀란다.
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(left: BorderSide(color: colors.danger, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: AppSize.iconSm,
            color: colors.danger,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이 모각코는 열리지 않아요',
                  style: context.texts.labelMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cancellation.label,
                  style: context.texts.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${relativeTime(cancellation.at, now)} 모임장이 접었어요',
                  style: context.texts.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 목록 카드에 붙는 한 줄.
///
/// 상세의 안내와 같은 말을 짧게 줄인다. 목록에서는 '왜'까지만 알면 되고,
/// 자세한 건 열어서 본다.
class CancelledLine extends StatelessWidget {
  const CancelledLine({super.key, required this.cancellation});

  final Cancellation cancellation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Icon(
          CupertinoIcons.exclamationmark_circle,
          size: AppSize.iconSm - 4,
          color: colors.danger,
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Flexible(
          child: Text(
            '취소 · ${cancellation.label}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.labelSmall?.copyWith(
              color: colors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
