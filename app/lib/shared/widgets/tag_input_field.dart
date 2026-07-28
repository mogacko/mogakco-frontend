import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 직접 입력해 태그를 붙이는 입력란.
///
/// 목록에 없는 것도 적을 수 있지만, 입력한 값이 [suggestions]에 대소문자만 다른
/// 형태로 존재하면 목록 쪽 표기로 바꿔 저장한다. 'java'를 쳐도 'Java'로 남아서
/// 나중에 태그로 사람을 찾을 때 표기가 갈리지 않는다.
class TagInputField extends StatefulWidget {
  const TagInputField({
    super.key,
    required this.suggestions,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
    required this.hintText,
    this.maxTags = 10,
  });

  /// 입력 중 추천으로 띄울 후보
  final List<String> suggestions;

  final Set<String> selected;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final String hintText;

  /// 태그가 많아지면 화면이 무너져서 상한을 둔다.
  final int maxTags;

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _query => _controller.text.trim();

  bool get _isFull => widget.selected.length >= widget.maxTags;

  /// 목록에 같은 이름이 있으면 그 표기를 따른다.
  String _canonical(String raw) {
    final trimmed = raw.trim();
    for (final suggestion in widget.suggestions) {
      if (suggestion.toLowerCase() == trimmed.toLowerCase()) return suggestion;
    }
    return trimmed;
  }

  bool _alreadyAdded(String value) {
    final lower = value.toLowerCase();
    return widget.selected.any((tag) => tag.toLowerCase() == lower);
  }

  /// 입력과 겹치면서 아직 안 고른 후보
  List<String> get _matches {
    if (_query.isEmpty) return const [];
    final lower = _query.toLowerCase();
    return widget.suggestions
        .where((s) => s.toLowerCase().contains(lower) && !_alreadyAdded(s))
        .take(6)
        .toList();
  }

  /// 목록에 없는 값을 새로 만들 수 있는지
  bool get _canCreate =>
      _query.isNotEmpty &&
      !_alreadyAdded(_query) &&
      !widget.suggestions.any((s) => s.toLowerCase() == _query.toLowerCase());

  void _add(String raw) {
    final value = _canonical(raw);
    if (value.isEmpty || _alreadyAdded(value) || _isFull) return;
    widget.onAdd(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final matches = _matches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          enabled: !_isFull,
          textInputAction: TextInputAction.done,
          onSubmitted: _add,
          decoration: InputDecoration(
            hintText: _isFull
                ? '최대 ${widget.maxTags}개까지 담을 수 있어요'
                : widget.hintText,
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.add_circle, color: colors.primary),
                    onPressed: () => _add(_query),
                    tooltip: '추가',
                  ),
          ),
        ),
        if (matches.isNotEmpty || _canCreate) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final match in matches)
                _SuggestionChip(label: match, onTap: () => _add(match)),
              if (_canCreate)
                _SuggestionChip(
                  label: '+ "$_query" 추가',
                  isCreate: true,
                  onTap: () => _add(_query),
                ),
            ],
          ),
        ],
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final tag in widget.selected)
                _SelectedChip(label: tag, onRemove: () => widget.onRemove(tag)),
            ],
          ),
        ],
      ],
    );
  }
}

/// 입력 중 뜨는 후보
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.onTap,
    this.isCreate = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Ink(
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isCreate ? colors.primary : colors.border,
            // 새로 만드는 항목은 목록에 있는 것과 구분되게 점선 대신 색으로 나눈다.
            style: BorderStyle.solid,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md - 2,
        ),
        child: Text(
          label,
          style: context.texts.labelMedium?.copyWith(
            color: isCreate ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 이미 담은 태그
class _SelectedChip extends StatelessWidget {
  const _SelectedChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: colors.primary),
      ),
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.sm,
        top: AppSpacing.md - 2,
        bottom: AppSpacing.md - 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.texts.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: AppSize.iconSm - 2,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
