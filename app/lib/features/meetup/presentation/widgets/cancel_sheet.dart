import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/haptics.dart';
import '../../domain/meetup.dart';

/// 모임을 접는 시트. 사유를 고르지 않으면 접을 수 없다.
///
/// 취소만 되고 이유가 없으면 기다리던 사람은 자기가 뭘 잘못했나 싶어진다.
/// 이유를 알면 다음 주에 다시 올지도 가늠이 된다.
Future<Cancellation?> showCancelSheet(
  BuildContext context, {
  required DateTime now,
  required int participantCount,
}) {
  return showModalBottomSheet<Cancellation>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _CancelSheet(now: now, participantCount: participantCount),
  );
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet({required this.now, required this.participantCount});

  final DateTime now;
  final int participantCount;

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  final _note = TextEditingController();

  CancelReason? _reason;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final reason = _reason;
    if (reason == null) return false;
    return !reason.needsNote || _note.text.trim().isNotEmpty;
  }

  void _submit() {
    Haptics.decide();
    Navigator.of(context).pop(
      Cancellation(
        reason: _reason!,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        at: widget.now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final others = widget.participantCount - 1;

    return SafeArea(
      top: false,
      child: Padding(
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
                      Text('모각코를 접을까요?', style: context.texts.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        // 몇 명이 기다리고 있는지를 먼저 알린다. 사람이 붙은
                        // 자리를 접는 일이라 되돌리기가 없다.
                        others > 0
                            ? '$others명에게 사유와 함께 알려드릴게요. 되돌릴 수 없어요'
                            : '아직 오기로 한 사람이 없어요. 되돌릴 수 없어요',
                        style: context.texts.labelSmall,
                      ),
                    ],
                  ),
                ),
                for (final reason in CancelReason.values)
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
                      maxLength: 60,
                      decoration: const InputDecoration(
                        hintText: '어떤 사정인지 적어주세요',
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
                        child: const Text('모각코 접기'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('그대로 두기'),
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

  final CancelReason reason;
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
