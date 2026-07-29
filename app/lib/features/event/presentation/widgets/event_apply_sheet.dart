import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/confirm_sheet.dart';
import '../../domain/event.dart';

/// 신청 전에 언제 어디서 얼마인지 다시 보여준다.
///
/// 행사는 참가비가 붙기도 하고 마감이 지나면 되돌릴 수 없어서, 모임보다
/// 확인이 더 필요하다.
///
/// 확인하면 true, 물러나면 false를 돌려준다.
Future<bool> confirmEventApply(
  BuildContext context, {
  required Event event,
  required DateTime now,
}) {
  final leaving = event.isApplied;

  return showConfirmSheet(
    context,
    title: leaving ? '신청을 취소할까요?' : '이 행사에 신청할까요?',
    confirmLabel: leaving ? '신청 취소' : '신청하기',
    tone: leaving ? ConfirmTone.danger : ConfirmTone.normal,
    details: _Summary(event: event, now: now),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.event, required this.now});

  final Event event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ConfirmSummary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.kind.label,
            style: context.texts.labelSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(event.title, style: context.texts.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: AppSpacing.lg),
          _Line(label: '일시', value: '${event.dateLabel} ${event.timeRangeLabel}'),
          const SizedBox(height: AppSpacing.sm),
          _Line(label: '장소', value: event.venue),
          const SizedBox(height: AppSpacing.sm),
          _Line(label: '참가비', value: event.feeLabel, emphasized: !event.isFree),
          const SizedBox(height: AppSpacing.sm),
          _Line(
            label: '신청 마감',
            value: '${event.applyBy.month}월 ${event.applyBy.day}일 '
                '(${event.ddayLabel(now)})',
          ),
        ],
      ),
    );
  }
}

/// 이름과 값이 한 줄.
///
/// 여기서는 라벨을 붙인다. 일시·장소·참가비·마감은 값만 봐서는 무엇인지
/// 가려지지 않고, 돈이 오가는 자리라 잘못 읽으면 곤란해진다.
class _Line extends StatelessWidget {
  const _Line({
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
