import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/full_height_scroll_view.dart';
import '../domain/term.dart';
import 'term_detail_screen.dart';
import 'widgets/signup_progress.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => TermsScreenState();
}

class TermsScreenState extends State<TermsScreen> {
  final _agreed = <Term>{};

  bool get _allAgreed => _agreed.length == Term.values.length;

  bool get _canProceed =>
      Term.values.where((t) => t.required).every(_agreed.contains);

  void _toggleAll(bool? value) {
    setState(() {
      _agreed
        ..clear()
        ..addAll(value == true ? Term.values : const <Term>[]);
    });
  }

  void _toggle(Term term, bool? value) {
    setState(() {
      if (value == true) {
        _agreed.add(term);
      } else {
        _agreed.remove(term);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: FullHeightScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SignupProgress(step: 1),
              const SizedBox(height: AppSpacing.xxl),
              Text('약관에 동의해 주세요', style: context.texts.headlineLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                '서비스 이용을 위해 아래 항목의 확인이 필요합니다',
                style: context.texts.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              _AgreeAllTile(value: _allAgreed, onChanged: _toggleAll),
              const SizedBox(height: AppSpacing.lg),
              Divider(color: colors.border),
              const SizedBox(height: AppSpacing.sm),
              for (final term in Term.values)
                _TermTile(
                  term: term,
                  value: _agreed.contains(term),
                  onChanged: (v) => _toggle(term, v),
                  onOpenDetail: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TermDetailScreen(term: term),
                    ),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _canProceed
                    ? () => context.push(AppRoute.signupChapter)
                    : null,
                child: const Text('동의하고 계속하기'),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreeAllTile extends StatelessWidget {
  const _AgreeAllTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Ink(
        decoration: BoxDecoration(
          color: value
              ? colors.primary.withValues(alpha: 0.08)
              : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: value ? colors.primary : colors.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Checkbox(value: value, onChanged: onChanged),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text('전체 동의', style: context.texts.titleLarge)),
          ],
        ),
      ),
    );
  }
}

class _TermTile extends StatelessWidget {
  const _TermTile({
    required this.term,
    required this.value,
    required this.onChanged,
    required this.onOpenDetail,
  });

  final Term term;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Checkbox(value: value, onChanged: onChanged),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                term.label,
                style: context.texts.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            // 전문 보기. 체크와 겹치지 않도록 아이콘만 따로 누를 수 있게 한다.
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                size: AppSize.iconMd,
                color: colors.textTertiary,
              ),
              tooltip: '${'\$'}{term.title} 전문 보기',
              onPressed: onOpenDetail,
            ),
          ],
        ),
      ),
    );
  }
}
