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
/// 메뉴는 로고 바로 아래에 뜨고 지금 지역은 빼고 보여준다.
/// 어디에 있는지는 헤더가 이미 말하고 있어 목록에 또 둘 이유가 없다.
class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key});

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  /// 화살표 방향을 메뉴 상태에 맞추기 위해 따로 들고 있는다.
  bool _menuOpen = false;

  void _select(Chapter chapter) {
    ref.read(currentChapterProvider.notifier).change(chapter);
    setState(() => _menuOpen = false);
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
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _ChapterMenu(
                current: current,
                open: _menuOpen,
                onOpened: () => setState(() => _menuOpen = true),
                onDismissed: () => setState(() => _menuOpen = false),
                onSelected: _select,
              ),
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
        Divider(color: colors.border, height: 0.5, thickness: 0.5),
      ],
    );
  }
}

/// 워드마크 + 화살표를 누르면 지역 목록이 바로 아래에 뜬다.
class _ChapterMenu extends StatelessWidget {
  const _ChapterMenu({
    required this.current,
    required this.open,
    required this.onOpened,
    required this.onDismissed,
    required this.onSelected,
  });

  final Chapter current;
  final bool open;
  final VoidCallback onOpened;
  final VoidCallback onDismissed;
  final ValueChanged<Chapter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopupMenuButton<Chapter>(
      // 앵커 바로 아래에 붙여 어디서 나온 메뉴인지 드러낸다.
      offset: const Offset(0, 34),
      onOpened: onOpened,
      onCanceled: onDismissed,
      onSelected: onSelected,
      tooltip: '지역 바꾸기',
      color: colors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      menuPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.border, width: 0.5),
      ),
      // 지금 지역은 헤더 워드마크가 이미 보여주므로 목록에서 뺀다.
      itemBuilder: (context) => [
        for (final chapter in Chapter.open.where((c) => c != current))
          PopupMenuItem<Chapter>(
            value: chapter,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: MogackoLogo.chapter(chapter: chapter, size: 22),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MogackoLogo.chapter(chapter: current, size: 24),
          const SizedBox(width: AppSpacing.xs),
          AnimatedRotation(
            turns: open ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: AppSize.iconMd,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
