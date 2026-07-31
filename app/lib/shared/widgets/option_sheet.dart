import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 몇 가지 중 하나를 고르는 시트.
///
/// 항목이 서넛이고 고르면 바로 반영되는 자리에 쓴다. 새 화면으로 들어갔다
/// 나오게 하면 되돌아올 때 방금 무엇을 바꿨는지 다시 찾게 된다.
///
/// 지금 고른 것에 체크를 둔다. 무엇이 켜져 있는지 모르고 고르면 같은 것을
/// 다시 고르는 일이 생긴다.
///
/// 고르면 그 값을, 물러나면 null 을 돌려준다.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T option) labelOf,
  String Function(T option)? descriptionOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _OptionSheet<T>(
      title: title,
      options: options,
      selected: selected,
      labelOf: labelOf,
      descriptionOf: descriptionOf,
    ),
  );
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.descriptionOf,
  });

  final String title;
  final List<T> options;
  final T selected;
  final String Function(T option) labelOf;
  final String Function(T option)? descriptionOf;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final descriptionOf = this.descriptionOf;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 아래로 내려 닫을 수 있다는 표시.
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Text(title, style: context.texts.headlineMedium),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final option in options)
              _OptionRow(
                label: labelOf(option),
                description: descriptionOf?.call(option),
                selected: option == selected,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final description = this.description;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.texts.bodyLarge?.copyWith(
                        // 고른 것만 굵기와 색으로 올린다. 체크만으로는
                        // 훑을 때 눈에 잘 안 들어온다.
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected ? colors.primary : colors.textPrimary,
                      ),
                    ),
                    if (description != null)
                      Text(description, style: context.texts.labelSmall),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  CupertinoIcons.checkmark,
                  size: AppSize.iconSm,
                  color: colors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
