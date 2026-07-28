import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/domain/chapter.dart';
import '../../../../shared/providers/current_chapter_provider.dart';
import '../../../../shared/widgets/mogacko_logo.dart';

/// 홈 상단 바.
///
/// 현재 지역의 워드마크를 왼쪽에 두고, 그 옆 화살표로 지역을 바꾼다.
/// 목록은 헤더 바로 아래로 밀려 내려온다. 한 손으로 쓰는 화면이라
/// 별도 다이얼로그를 띄우는 대신 제자리에서 펼치고 접는다.
class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key});

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  void _select(Chapter chapter) {
    ref.read(currentChapterProvider.notifier).change(chapter);
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = ref.watch(currentChapterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // 워드마크에 지역명이 들어 있어 현재 지역이 곧 로고로 드러난다.
              MogackoLogo.chapter(chapter: current, size: 24),
              _ChevronButton(expanded: _expanded, onTap: _toggle),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_none,
                  color: colors.textSecondary,
                ),
                tooltip: '알림',
              ),
            ],
          ),
        ),
        // 접혀 있을 때 높이 0으로 줄어 본문이 위로 붙는다.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? _ChapterList(current: current, onSelect: _select)
              : const SizedBox(width: double.infinity),
        ),
        Divider(color: colors.border, height: 1),
      ],
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: '지역 바꾸기',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 220),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: AppSize.iconMd,
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterList extends StatelessWidget {
  const _ChapterList({required this.current, required this.onSelect});

  final Chapter current;
  final ValueChanged<Chapter> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      color: colors.surfaceAlt,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          for (final chapter in Chapter.open)
            _ChapterRow(
              chapter: chapter,
              selected: chapter == current,
              onTap: () => onSelect(chapter),
            ),
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Text('다른 지역도 순차적으로 열립니다', style: context.texts.labelSmall),
          ),
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Text(
              chapter.label,
              style: context.texts.bodyLarge?.copyWith(
                color: selected ? colors.primary : colors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(Icons.check, size: AppSize.iconMd, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
