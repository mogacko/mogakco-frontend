import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 이름과 값이 한 줄.
///
/// 행사에서는 라벨을 붙인다. 일시·장소·참가비·마감은 값만 봐서는 무엇인지
/// 가려지지 않고, 돈이 오가는 자리라 잘못 읽으면 곤란해진다.
class EventInfoLine extends StatelessWidget {
  const EventInfoLine({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;

  /// 참가비처럼 놓치면 안 되는 값
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              color: colors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.texts.labelMedium?.copyWith(
              color: emphasized ? colors.textPrimary : colors.textSecondary,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
