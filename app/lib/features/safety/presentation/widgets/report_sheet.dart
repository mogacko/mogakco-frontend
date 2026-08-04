import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/haptics.dart';
import '../../domain/report.dart';
import '../safety_provider.dart';

/// 신고 시트를 띄우고 접수됐는지 돌려준다.
///
/// 이미 신고한 것이면 시트를 열지 않는다. 두 번째 신고는 접수되지도 않는데
/// 사유를 고르게 하면 무언가 한 것 같은 착각만 남는다.
Future<bool> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
}) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(target: target, targetId: targetId),
  );
  return done ?? false;
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.target, required this.targetId});

  final ReportTarget target;
  final String targetId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _note = TextEditingController();

  ReportReason? _reason;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// 기타를 골랐으면 무엇이 문제인지 적어야 한다. 사유가 '기타'뿐인 신고는
  /// 운영진이 볼 때 아무 정보가 없다.
  bool get _canSubmit {
    final reason = _reason;
    if (reason == null) return false;
    return !reason.needsNote || _note.text.trim().isNotEmpty;
  }

  void _submit() {
    ref
        .read(reportsProvider.notifier)
        .add(
          target: widget.target,
          targetId: widget.targetId,
          reason: _reason!,
          note: _note.text,
        );
    Haptics.decide();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Padding(
        // 기타를 고르면 입력칸이 열린다. 키보드가 시트를 가리지 않게 밀어 올린다.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.target.label} 신고',
                        style: context.texts.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '접수된 내용은 운영진이 확인합니다',
                        style: context.texts.labelSmall,
                      ),
                    ],
                  ),
                ),
                for (final reason in ReportReason.values)
                  _ReasonRow(
                    reason: reason,
                    selected: _reason == reason,
                    onTap: () {
                      Haptics.toggle();
                      setState(() => _reason = reason);
                    },
                  ),
                if (_reason?.needsNote ?? false)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      0,
                    ),
                    child: TextField(
                      controller: _note,
                      onChanged: (_) => setState(() {}),
                      autofocus: true,
                      maxLength: 200,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '무엇이 문제인지 적어주세요',
                        counterText: '',
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: _canSubmit ? _submit : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.danger,
                        ),
                        child: const Text('신고하기'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('취소'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final ReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.label,
                    style: context.texts.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 사유마다 무엇을 가리키는지 적어둔다. '기타'로 몰리는 건
                  // 대개 어느 항목이 자기 경우인지 몰라서다.
                  Text(reason.description, style: context.texts.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: AppSize.iconMd,
              color: selected ? colors.primary : colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
