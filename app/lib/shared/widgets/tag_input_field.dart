import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 서버에서 추천어를 가져오는 함수.
///
/// 다른 사용자들이 실제로 입력한 값을 집계해 돌려주는 용도다.
typedef TagSearch = Future<List<String>> Function(String query);

/// 직접 입력해 태그를 붙이는 입력란.
///
/// 목록에 없는 것도 적을 수 있지만, 입력한 값이 [suggestions]에 대소문자만 다른
/// 형태로 존재하면 목록 쪽 표기로 바꿔 저장한다. 'java'를 쳐도 'Java'로 남아서
/// 나중에 태그로 사람을 찾을 때 표기가 갈리지 않는다.
///
/// [onSearch]를 넘기면 서버 추천이 함께 뜬다. 이때만 [searchDebounce]만큼
/// 입력이 멎기를 기다렸다가 호출한다. 로컬 [suggestions] 필터는 항상 즉시
/// 반영되므로 디바운스가 타이핑 반응을 늦추지 않는다.
class TagInputField extends StatefulWidget {
  const TagInputField({
    super.key,
    required this.suggestions,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
    required this.hintText,
    this.maxTags = 10,
    this.onSearch,
    this.searchDebounce = const Duration(seconds: 1),
  });

  /// 입력 중 추천으로 띄울 후보. 앱에 내장된 목록이다.
  final List<String> suggestions;

  final Set<String> selected;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final String hintText;

  /// 태그가 많아지면 화면이 무너져서 상한을 둔다.
  final int maxTags;

  /// 서버 추천. null이면 로컬 목록만 쓴다.
  final TagSearch? onSearch;

  /// [onSearch] 호출 전 대기 시간. 타이핑 한 글자마다 요청이 나가지 않게 한다.
  final Duration searchDebounce;

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _controller = TextEditingController();

  Timer? _debounce;

  /// 서버에서 받아온 추천
  List<String> _remote = const [];

  /// 늦게 도착한 응답이 최신 결과를 덮어쓰지 않도록 요청 순번을 센다.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    // 로컬 필터는 지연 없이 바로 반영한다.
    setState(() {});

    final search = widget.onSearch;
    if (search == null) return;

    _debounce?.cancel();
    if (_query.isEmpty) {
      setState(() => _remote = const []);
      return;
    }

    _debounce = Timer(widget.searchDebounce, () => _fetch(search, _query));
  }

  Future<void> _fetch(TagSearch search, String query) async {
    final id = ++_requestId;
    try {
      final result = await search(query);
      // 그 사이 더 최근 요청이 나갔거나 화면이 사라졌으면 버린다.
      if (!mounted || id != _requestId) return;
      setState(() => _remote = result);
    } catch (_) {
      // 추천은 있으면 좋은 정보다. 실패해도 입력을 막지 않는다.
      if (!mounted || id != _requestId) return;
      setState(() => _remote = const []);
    }
  }

  String get _query => _controller.text.trim();

  bool get _isFull => widget.selected.length >= widget.maxTags;

  /// 목록에 같은 이름이 있으면 그 표기를 따른다.
  ///
  /// 서버 추천도 같은 기준으로 본다. 남들이 이미 'Svelte'로 적어둔 값이 있으면
  /// 'svelte'를 쳐도 그 표기로 합류시켜야 태그가 갈리지 않는다.
  String _canonical(String raw) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();
    for (final candidate in [...widget.suggestions, ..._remote]) {
      if (candidate.toLowerCase() == lower) return candidate;
    }
    return trimmed;
  }

  bool _alreadyAdded(String value) {
    final lower = value.toLowerCase();
    return widget.selected.any((tag) => tag.toLowerCase() == lower);
  }

  /// 입력과 겹치면서 아직 안 고른 후보.
  ///
  /// 로컬 목록을 앞에 두고 서버 추천을 뒤에 붙인다. 표기가 같으면 하나만 남긴다.
  List<String> get _matches {
    if (_query.isEmpty) return const [];
    final lower = _query.toLowerCase();

    final seen = <String>{};
    final result = <String>[];
    for (final candidate in [...widget.suggestions, ..._remote]) {
      if (!candidate.toLowerCase().contains(lower)) continue;
      if (_alreadyAdded(candidate)) continue;
      if (!seen.add(candidate.toLowerCase())) continue;
      result.add(candidate);
      if (result.length == 6) break;
    }
    return result;
  }

  /// 목록에 없는 값을 새로 만들 수 있는지
  bool get _canCreate {
    if (_query.isEmpty || _alreadyAdded(_query)) return false;
    final lower = _query.toLowerCase();
    return !widget.suggestions.any((s) => s.toLowerCase() == lower) &&
        !_remote.any((s) => s.toLowerCase() == lower);
  }

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
                    icon: Icon(CupertinoIcons.add_circled_solid, color: colors.primary),
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
          color: colors.surface,
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
                CupertinoIcons.xmark,
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
