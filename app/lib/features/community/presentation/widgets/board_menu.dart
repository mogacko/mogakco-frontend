import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/post.dart';

/// 제목을 눌러 게시판을 바꾼다.
///
/// 게시판이 셋뿐이라 알약 줄로 늘어놓을 수도 있지만, 그러면 그 아래 분류
/// 필터와 알약 줄이 두 겹으로 쌓여 무엇이 무엇을 좁히는지 흐려진다. 게시판은
/// 큰 갈래이므로 제목 자리에서 바꾸고, 분류는 그 아래에 남긴다.
///
/// 지금 보고 있는 게시판은 목록에서 뺀다. 제목이 이미 말하고 있다.
class BoardMenu extends StatefulWidget {
  const BoardMenu({super.key, required this.current, required this.onSelected});

  final PostBoard current;
  final ValueChanged<PostBoard> onSelected;

  @override
  State<BoardMenu> createState() => _BoardMenuState();
}

class _BoardMenuState extends State<BoardMenu> {
  /// 화살표 방향을 메뉴 상태에 맞추기 위해 따로 들고 있는다.
  bool _open = false;

  /// 메뉴 항목의 좌우 여백. 메뉴 위치를 맞출 때 같은 값을 되돌려 쓴다.
  static const _itemPadding = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopupMenuButton<PostBoard>(
      // 메뉴는 버튼 좌상단을 기준으로 놓인다. 항목 패딩만큼 왼쪽으로 당겨야
      // 메뉴 안 글자가 제목과 수직으로 맞는다.
      position: PopupMenuPosition.under,
      offset: const Offset(-_itemPadding, AppSpacing.sm),
      onOpened: () => setState(() => _open = true),
      onCanceled: () => setState(() => _open = false),
      onSelected: (board) {
        setState(() => _open = false);
        widget.onSelected(board);
      },
      tooltip: '게시판 바꾸기',
      color: colors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      menuPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.border, width: 0.5),
      ),
      itemBuilder: (context) => [
        for (final board in PostBoard.values.where((b) => b != widget.current))
          PopupMenuItem<PostBoard>(
            value: board,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: _itemPadding),
            child: Text(
              board.label,
              style: context.texts.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.current.label, style: context.texts.headlineLarge),
          const SizedBox(width: AppSpacing.xs),
          AnimatedRotation(
            turns: _open ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              CupertinoIcons.chevron_down,
              // 제목(26)에 딸린 보조 표시라 그보다 확실히 작아야 균형이 맞는다.
              size: 16,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
