import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 제목을 눌러 고르는 메뉴.
///
/// 항목이 대여섯을 넘거나 그 아래에 또 다른 필터가 붙는 화면에서 쓴다. 알약
/// 줄을 두 겹으로 쌓으면 무엇이 무엇을 좁히는지 흐려지는데, 큰 갈래를 제목
/// 자리로 올리면 아래는 한 겹만 남는다.
///
/// 지금 고른 것은 목록에서 뺀다. 제목이 이미 말하고 있다.
class TitleMenu<T> extends StatefulWidget {
  const TitleMenu({
    super.key,
    required this.current,
    required this.options,
    required this.labelOf,
    required this.onSelected,
    this.tooltip,
  });

  final T current;
  final List<T> options;
  final String Function(T option) labelOf;
  final ValueChanged<T> onSelected;

  final String? tooltip;

  @override
  State<TitleMenu<T>> createState() => _TitleMenuState<T>();
}

class _TitleMenuState<T> extends State<TitleMenu<T>> {
  /// 화살표 방향을 메뉴 상태에 맞추기 위해 따로 들고 있는다.
  bool _open = false;

  /// 메뉴 항목의 좌우 여백. 메뉴 위치를 맞출 때 같은 값을 되돌려 쓴다.
  static const _itemPadding = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopupMenuButton<T>(
      // 메뉴는 버튼 좌상단을 기준으로 놓인다. 항목 패딩만큼 왼쪽으로 당겨야
      // 메뉴 안 글자가 제목과 수직으로 맞는다.
      position: PopupMenuPosition.under,
      offset: const Offset(-_itemPadding, AppSpacing.sm),
      onOpened: () => setState(() => _open = true),
      onCanceled: () => setState(() => _open = false),
      onSelected: (value) {
        setState(() => _open = false);
        widget.onSelected(value);
      },
      tooltip: widget.tooltip ?? '',
      color: colors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      menuPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.border, width: 0.5),
      ),
      itemBuilder: (context) => [
        for (final option in widget.options.where((o) => o != widget.current))
          PopupMenuItem<T>(
            value: option,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: _itemPadding),
            child: Text(
              widget.labelOf(option),
              style: context.texts.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.labelOf(widget.current),
            style: context.texts.headlineLarge,
          ),
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
