import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 이름 붙은 입력 한 칸.
///
/// 라벨을 입력창 안이 아니라 위에 둔다. 안에 넣으면 채우고 나서 무엇을 적은
/// 칸인지 사라진다 — 폼이 길수록 다시 훑을 일이 잦다.
class FormFieldBlock extends StatelessWidget {
  const FormFieldBlock({
    super.key,
    required this.label,
    required this.child,
    this.optional = false,
    this.hint,
  });

  final String label;
  final Widget child;

  /// 비워도 되는 칸. 별표 대신 '선택'이라 적는다.
  final bool optional;

  /// 라벨 아래 한 줄 설명
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hint = this.hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              label,
              style: context.texts.labelMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: AppSpacing.xs + 2),
              Text('선택', style: context.texts.labelSmall),
            ],
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint, style: context.texts.labelSmall),
        ],
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

/// 작은 수를 올리고 내리는 칸.
///
/// 숫자 입력창보다 낫다. 정원은 대개 한 자리에서 두 자리 사이라 키보드를
/// 올렸다 내리는 품이 값보다 크다.
class CountStepper extends StatelessWidget {
  const CountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 2,
    this.max = 50,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Step(
            icon: Icons.remove,
            label: '줄이기',
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: context.texts.labelMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _Step(
            icon: Icons.add,
            label: '늘리기',
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: AppSize.iconSm,
            // 끝에 닿으면 눌러도 소용없다는 걸 색으로 먼저 알린다.
            color: onTap == null ? colors.textTertiary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
