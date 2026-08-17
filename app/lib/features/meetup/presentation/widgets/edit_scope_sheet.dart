import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/edit_scope.dart';

/// 정기 모각코를 고칠 때 어디까지 미칠지 고르는 시트.
///
/// 정기 모임에서 장소·요일·시각·정원이 실제로 바뀌었을 때만 띄운다. 소개글만
/// 고쳤는데도 뜨면 금방 안 읽고 누르게 되고, 그러면 정작 필요할 때도 안 읽는다.
Future<EditScope?> showEditScopeSheet(
  BuildContext context, {
  required String what,
}) {
  return showModalBottomSheet<EditScope>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _ScopeSheet(what: what),
  );
}

class _ScopeSheet extends StatelessWidget {
  const _ScopeSheet({required this.what});

  /// 무엇을 바꾸는지. '장소를 바꿉니다'처럼 첫 줄에 선다.
  final String what;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(what, style: context.texts.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '매주 열리는 자리예요',
                    style: context.texts.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            for (final scope in EditScope.values) ...[
              Divider(height: 1, color: colors.border),
              _ScopeRow(scope: scope),
            ],
            Divider(height: 1, color: colors.border),
            // 되돌릴 수 없는 갈림길이라 그만두는 길을 열어 둔다.
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppSize.buttonHeight),
              ),
              child: const Text('그만두기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({required this.scope});

  final EditScope scope;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () => Navigator.of(context).pop(scope),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scope.label,
              style: context.texts.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              scope.description,
              style: context.texts.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
