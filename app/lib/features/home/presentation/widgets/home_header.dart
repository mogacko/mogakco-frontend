import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/domain/chapter.dart';
import '../../../../shared/providers/current_chapter_provider.dart';
import '../../../../shared/utils/korean_particle.dart';
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
    setState(() => _menuOpen = false);

    // 아직 열지 않은 지역은 왜 안 되는지 알려준다.
    // 모바일에는 hover가 없어 눌러봐야 이유를 알 수 있다.
    if (!chapter.isOpen) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${chapter.label}${KoreanParticle.topic(chapter.label)} '
              '아직 준비 중이에요',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }

    ref.read(currentChapterProvider.notifier).change(chapter);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = ref.watch(currentChapterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.sm,
            AppSpacing.screenHorizontal - AppSpacing.sm,
            AppSpacing.sm,
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
              // IconButton 은 48x48 터치 영역을 차지해 헤더를 두껍게 만든다.
              // 손가락이 닿을 만큼만 남기고 직접 그린다.
              Semantics(
                button: true,
                label: '알림',
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      CupertinoIcons.bell,
                      size: AppSize.iconMd,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  /// 메뉴 항목의 좌우 여백. 메뉴 위치를 맞출 때 같은 값을 되돌려 쓴다.
  static const _itemPadding = AppSpacing.lg;

  final Chapter current;
  final bool open;
  final VoidCallback onOpened;
  final VoidCallback onDismissed;
  final ValueChanged<Chapter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopupMenuButton<Chapter>(
      // 메뉴는 버튼 좌상단을 기준으로 놓인다. 항목 패딩만큼 왼쪽으로 당겨야
      // 메뉴 안 워드마크가 헤더 워드마크와 수직으로 맞는다.
      position: PopupMenuPosition.under,
      offset: const Offset(-_itemPadding, AppSpacing.sm),
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
      // 아직 열지 않은 지역도 함께 보여줘 어디까지 넓어질지 드러낸다.
      itemBuilder: (context) => [
        for (final chapter in Chapter.values.where((c) => c != current))
          PopupMenuItem<Chapter>(
            value: chapter,
            // 준비 중인 지역도 누를 수는 있어야 안내를 띄운다.
            // 지역을 실제로 바꿀지는 onSelected 에서 가른다.
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: _itemPadding),
            child: _MenuRow(chapter: chapter),
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

/// 메뉴 한 줄.
///
/// 지역명은 텍스트로 둔다. 항목이 열 개까지 늘어나면 워드마크가 세로로 쌓여
/// 훑어보기 어렵고, 로고마다 앞부분 도형이 반복돼 지역명만 골라내야 한다.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final open = chapter.isOpen;

    // Spacer로 양끝에 붙이면 지역명과 표식이 헤더보다 넓게 벌어진다.
    // 필요한 만큼만 차지하고 둘 사이는 좁게 붙여 둔다.
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          chapter.label,
          // 로고 획이 굵어 기본 굵기로는 옆에서 가볍게 보인다.
          // 활성·비활성은 굵기가 아니라 색으로 가른다.
          style: context.texts.bodyLarge?.copyWith(
            color: open ? colors.textPrimary : colors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!open) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(
            CupertinoIcons.nosign,
            size: AppSize.iconSm,
            color: colors.textTertiary,
          ),
        ],
      ],
    );

    if (open) return row;

    // 웹·데스크톱에서는 올려두면, 모바일에서는 길게 누르면 뜬다.
    // 짧게 누르면 대신 안내가 나온다.
    return Semantics(
      hint: '준비 중인 지역',
      child: Tooltip(
        message:
            '${chapter.label}${KoreanParticle.topic(chapter.label)} '
            '아직 준비 중이에요',
        child: row,
      ),
    );
  }
}
