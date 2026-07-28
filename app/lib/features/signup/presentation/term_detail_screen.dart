import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/term.dart';

/// 약관 전문.
///
/// 동의 화면에서 항목을 눌러 들어온다. 여기서는 읽기만 하고, 동의 여부는
/// 앞 화면의 체크박스로 정한다.
class TermDetailScreen extends StatelessWidget {
  const TermDetailScreen({super.key, required this.term});

  final Term term;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(leading: const BackButton(), title: Text(term.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.sm,
            AppSpacing.screenHorizontal,
            AppSpacing.huge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Badge(required: term.required),
              const SizedBox(height: AppSpacing.xl),
              Text(
                term.body.trim(),
                // 조문이 길어 본문 행간을 넓혀 읽기 편하게 둔다.
                style: context.texts.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.required});

  final bool required;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = required ? colors.primary : colors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      child: Text(
        required ? '필수 동의' : '선택 동의',
        style: context.texts.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
