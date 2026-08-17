import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'confirm_sheet.dart';

/// 내가 올린 것에 할 수 있는 일.
enum OwnerAction { edit, delete }

/// 수정·삭제를 고르는 시트.
///
/// 남의 것에 붙는 신고·차단과 같은 자리('⋯')를 쓴다. 내 것이냐 남의 것이냐에
/// 따라 버튼 위치가 달라지면 누를 때마다 어디였는지 다시 찾게 된다.
///
/// 삭제는 여기서 바로 하지 않고 한 번 더 묻는다. 되돌릴 수 없는 일이고,
/// 수정 바로 아래 있어서 손이 미끄러지기 쉽다.
///
/// [deleteTitle] 이 없으면 되묻지 않고 그대로 돌려준다. 부르는 쪽에 이미
/// 되묻는 시트가 있을 때 쓴다 — 모각코 접기는 사유까지 받으므로 그 시트가
/// 곧 확인이고, 여기서 한 번 더 물으면 두 번 확인하게 된다.
Future<OwnerAction?> showOwnerSheet(
  BuildContext context, {
  required String what,
  String deleteLabel = '삭제',
  String? deleteTitle,
  String? deleteDescription,
}) async {
  final picked = await showModalBottomSheet<OwnerAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _OwnerSheet(what: what, deleteLabel: deleteLabel),
  );

  if (picked != OwnerAction.delete || deleteTitle == null) return picked;
  if (!context.mounted) return null;

  final ok = await showConfirmSheet(
    context,
    title: deleteTitle,
    details: deleteDescription == null
        ? null
        : Text(
            deleteDescription,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
    confirmLabel: '삭제',
    tone: ConfirmTone.danger,
  );

  return ok ? OwnerAction.delete : null;
}

/// 상세 화면 오른쪽 위의 '⋯'. 내가 올린 것에만 붙는다.
class OwnerMenuButton extends StatelessWidget {
  const OwnerMenuButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '더보기',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            CupertinoIcons.ellipsis,
            size: AppSize.iconMd,
            color: context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _OwnerSheet extends StatelessWidget {
  const _OwnerSheet({required this.what, required this.deleteLabel});

  final String what;
  final String deleteLabel;

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
            _Row(
              icon: CupertinoIcons.pencil,
              label: '$what 고치기',
              onTap: () => Navigator.of(context).pop(OwnerAction.edit),
            ),
            Divider(height: 1, color: colors.border),
            _Row(
              icon: CupertinoIcons.trash,
              label: '$what $deleteLabel',
              danger: true,
              onTap: () => Navigator.of(context).pop(OwnerAction.delete),
            ),
            Divider(height: 1, color: colors.border),
            _Row(
              icon: CupertinoIcons.xmark,
              label: '닫기',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = danger ? colors.danger : colors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(icon, size: AppSize.iconMd, color: foreground),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: context.texts.bodyLarge?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
