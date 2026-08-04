import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/haptics.dart';
import '../../../../shared/widgets/confirm_sheet.dart';
import '../../../member/presentation/member_provider.dart';
import '../../domain/report.dart';
import '../safety_provider.dart';
import 'report_sheet.dart';

/// 상세 화면 오른쪽 위의 '⋯'.
///
/// 신고와 차단은 자주 쓰는 기능이 아니다. 화면에 버튼으로 세워두면 볼 때마다
/// 눈에 걸리는데, 정작 필요한 순간은 드물다. 한 겹 안에 넣어 둔다.
class SafetyMenuButton extends ConsumerWidget {
  const SafetyMenuButton({
    super.key,
    required this.target,
    required this.targetId,
    this.authorId,
  });

  final ReportTarget target;
  final String targetId;

  /// 이 글·모임을 올린 사람. 넘기면 차단도 함께 뜬다.
  final String? authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 내 것에는 신고할 것도 차단할 것도 없다.
    final isMine = authorId != null && authorId == ref.watch(myIdProvider);
    if (isMine) return const SizedBox.shrink();

    return Semantics(
      button: true,
      label: '더보기',
      child: InkWell(
        onTap: () => showSafetySheet(
          context,
          ref,
          target: target,
          targetId: targetId,
          memberId: authorId,
        ),
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

/// 신고·차단을 고르는 시트.
///
/// [memberId] 를 넘기면 차단이 함께 뜬다. 이미 차단한 사람이면 해제로 바뀐다.
Future<void> showSafetySheet(
  BuildContext context,
  WidgetRef ref, {
  required ReportTarget target,
  required String targetId,
  String? memberId,
}) async {
  final blocked = memberId != null && ref.read(blockedProvider).contains(memberId);
  final reported = ref.read(reportsProvider.notifier).has(target, targetId);

  final action = await showModalBottomSheet<_SafetyAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _SafetySheet(
      target: target,
      memberId: memberId,
      blocked: blocked,
      reported: reported,
    ),
  );

  if (action == null || !context.mounted) return;

  switch (action) {
    case _SafetyAction.report:
      final done = await showReportSheet(
        context,
        target: target,
        targetId: targetId,
      );
      if (done && context.mounted) {
        _toast(context, '신고가 접수됐어요. 확인 후 조치할게요');
      }

    case _SafetyAction.block:
      final ok = await showConfirmSheet(
        context,
        title: '$memberId님을 차단할까요?',
        details: Text(
          '이 사람의 글과 댓글이 보이지 않고, 이 사람도 회원님의 프로필을 볼 수 없어요.',
          style: context.texts.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        confirmLabel: '차단',
        tone: ConfirmTone.danger,
      );
      if (!ok || !context.mounted) return;
      ref.read(blockedProvider.notifier).block(memberId!);
      _toast(context, '$memberId님을 차단했어요');

    case _SafetyAction.unblock:
      ref.read(blockedProvider.notifier).unblock(memberId!);
      _toast(context, '$memberId님의 차단을 풀었어요');
  }
}

void _toast(BuildContext context, String message) {
  Haptics.decide();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}

enum _SafetyAction { report, block, unblock }

class _SafetySheet extends StatelessWidget {
  const _SafetySheet({
    required this.target,
    required this.memberId,
    required this.blocked,
    required this.reported,
  });

  final ReportTarget target;
  final String? memberId;
  final bool blocked;
  final bool reported;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final memberId = this.memberId;

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
              icon: CupertinoIcons.exclamationmark_triangle,
              // 두 번째 신고는 접수되지 않는다. 누를 수 있게 두면 눌러보고 나서야
              // 안다.
              label: reported ? '이미 신고했어요' : '${target.label} 신고',
              danger: !reported,
              onTap: reported
                  ? null
                  : () => Navigator.of(context).pop(_SafetyAction.report),
            ),
            if (memberId != null) ...[
              Divider(height: 1, color: colors.border),
              _Row(
                icon: blocked
                    ? CupertinoIcons.person_crop_circle_badge_checkmark
                    : CupertinoIcons.nosign,
                label: blocked ? '$memberId님 차단 해제' : '$memberId님 차단',
                danger: !blocked,
                onTap: () => Navigator.of(
                  context,
                ).pop(blocked ? _SafetyAction.unblock : _SafetyAction.block),
              ),
            ],
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
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = onTap == null
        ? colors.textTertiary
        : (danger ? colors.danger : colors.textPrimary);

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
