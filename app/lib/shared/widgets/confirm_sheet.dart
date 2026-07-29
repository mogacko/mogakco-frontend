import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 확인 시트의 성격.
///
/// 되돌리기 어려운 쪽은 색으로 구분한다. 취소·탈퇴는 누르고 나면 자리가
/// 남에게 넘어가 되돌릴 수 없다.
enum ConfirmTone { normal, danger }

/// 결정하기 전에 무엇을 고른 것인지 다시 보여주는 시트.
///
/// 버튼 한 번에 신청이 나가면 잘못 눌렀을 때 되돌릴 방법이 없다. 목록에서는
/// 이웃 항목을 누르기도 쉬워서, 무엇을 고른 것인지 확인하고 결정하게 한다.
///
/// 시스템 얼럿 대신 시트를 쓰는 이유는 보여줄 것이 서너 줄을 넘어서다.
/// 얼럿 본문에 텍스트로 늘어놓으면 한 덩어리로 보여 눈에 들어오지 않는다.
///
/// 확인하면 true, 물러나면 false를 돌려준다.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  Widget? details,
  ConfirmTone tone = ConfirmTone.normal,
  String dismissLabel = '닫기',
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    // 기본 최대 높이가 화면의 절반이라 내용이 잘린다. 내용만큼 차지하게 둔다.
    isScrollControlled: true,
    // 시트 안에서 화면 크기를 재므로 안전영역을 직접 다룬다.
    useSafeArea: true,
    builder: (context) => _ConfirmSheet(
      title: title,
      details: details,
      confirmLabel: confirmLabel,
      dismissLabel: dismissLabel,
      tone: tone,
    ),
  );

  return result ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.details,
    required this.confirmLabel,
    required this.dismissLabel,
    required this.tone,
  });

  final String title;
  final Widget? details;
  final String confirmLabel;
  final String dismissLabel;
  final ConfirmTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      // 화면이 짧거나 글꼴을 키우면 내용이 넘친다. 그때는 시트 안에서 스크롤한다.
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
            Text(title, style: context.texts.headlineMedium),
            if (details != null) ...[
              const SizedBox(height: AppSpacing.xl),
              details!,
            ],
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              style: tone == ConfirmTone.danger
                  ? FilledButton.styleFrom(backgroundColor: colors.danger)
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dismissLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// 확인 시트 안에 놓는 요약 상자.
///
/// 무엇을 고른 것인지 한눈에 보여주는 자리다. 시트 배경과 한 단계 다른 면에
/// 올려 본문과 구분한다.
class ConfirmSummary extends StatelessWidget {
  const ConfirmSummary({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: child,
    );
  }
}
