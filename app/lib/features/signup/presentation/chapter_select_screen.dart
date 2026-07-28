import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/full_height_scroll_view.dart';
import '../../../shared/widgets/mogacko_logo.dart';
import '../domain/chapter.dart';
import 'widgets/signup_progress.dart';

/// 활동 지역 선택.
///
/// 운영 중인 지역([Chapter.open])만 고를 수 있다. 아직 열지 않은 지역은
/// 로고가 준비돼 있어도 노출하지 않고, 대신 안내 문구로 확장 예정을 알린다.
class ChapterSelectScreen extends StatefulWidget {
  const ChapterSelectScreen({super.key});

  @override
  State<ChapterSelectScreen> createState() => _ChapterSelectScreenState();
}

class _ChapterSelectScreenState extends State<ChapterSelectScreen> {
  Chapter? _selected;

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
              const SignupProgress(step: 2),
              const SizedBox(height: AppSpacing.xxl),
              Text('어느 지역에서 활동하세요?', style: context.texts.headlineLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                // 길어지면 마지막 글자만 다음 줄로 떨어진다. 한 줄에 맞춰 줄였다.
                '고른 지역의 모임이 먼저 보여요',
                style: context.texts.bodyLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              for (final chapter in Chapter.open) ...[
                _ChapterTile(
                  chapter: chapter,
                  selected: _selected == chapter,
                  onTap: () => setState(() => _selected = chapter),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                '다른 지역도 순차적으로 열립니다',
                style: context.texts.labelSmall,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _selected == null
                    ? null
                    : () => context.push(AppRoute.signupProfile),
                child: const Text('다음'),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.chapter,
    required this.selected,
    required this.onTap,
  });

  final Chapter chapter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Ink(
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.08)
              : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        child: Row(
          children: [
            // 워드마크에 이미 지역명이 들어 있어 별도 라벨을 두지 않는다.
            MogackoLogo.chapter(chapter: chapter, size: 26),
            const Spacer(),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? colors.primary : colors.textTertiary,
              size: AppSize.iconMd,
            ),
          ],
        ),
      ),
    );
  }
}
