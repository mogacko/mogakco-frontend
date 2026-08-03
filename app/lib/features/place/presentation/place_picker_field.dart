import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/widgets/form_field_block.dart';
import '../../../shared/widgets/static_map.dart';
import '../domain/place.dart';
import 'place_search_provider.dart';

/// 장소를 검색해서 고르는 칸.
///
/// '어디서'와 '주소'를 따로 받지 않는다. 두 칸으로 두면 사람이 이름은 이름대로
/// 주소는 주소대로 적어야 하는데, 그렇게 모은 주소로는 지도를 그릴 수 없다.
/// 검색으로 고르게 하면 이름·주소·좌표가 한 번에 딸려 온다.
class PlacePickerField extends ConsumerStatefulWidget {
  const PlacePickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '장소',
    this.hint = '카페나 스터디룸 이름으로 검색하세요',
  });

  /// 고른 장소. 아직 안 골랐으면 null.
  final Place? value;
  final ValueChanged<Place?> onChanged;

  final String label;
  final String hint;

  @override
  ConsumerState<PlacePickerField> createState() => _PlacePickerFieldState();
}

class _PlacePickerFieldState extends ConsumerState<PlacePickerField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  Timer? _debounce;

  /// 실제로 검색에 넘긴 말. 입력하는 대로가 아니라 잠깐 멈춘 뒤에 따라온다.
  String _query = '';

  /// 한 글자 칠 때마다 서버를 부르면 '모모스커피'에 다섯 번이 나간다. 250ms 는
  /// 이어 치는 사이보다는 길고 멈췄다고 느끼기에는 짧다.
  static const _debounceDelay = Duration(milliseconds: 250);

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onKeywordChanged(String keyword) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (mounted) setState(() => _query = keyword);
    });
  }

  void _select(Place place) {
    Haptics.toggle();
    _focus.unfocus();
    _controller.clear();
    setState(() => _query = '');
    widget.onChanged(place);
  }

  void _clear() {
    widget.onChanged(null);
    // 다시 고르려고 지운 것이므로 키보드까지 올려 준다. 한 번 더 눌러야
    // 칠 수 있게 두면 '변경'이 두 동작이 된다.
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.value;

    return FormFieldBlock(
      label: widget.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (place == null) _search() else _picked(place),
          if (place != null) ...[
            const SizedBox(height: AppSpacing.md),
            // 지도는 확인용이다. 눌러서 지도 앱으로 나가면 쓰던 폼이 날아가므로
            // 여기서는 열지 않는다. 상세 화면의 지도가 그 역할을 한다.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: StaticMap(
                latitude: place.latitude,
                longitude: place.longitude,
                height: 140,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _search() {
    final query = _query.trim();
    final chapter = ref.watch(currentChapterProvider);
    final results = query.length < placeSearchMinLength
        ? const AsyncValue<List<Place>>.data([])
        : ref.watch(
            placeSearchProvider((keyword: query, chapter: chapter)),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onKeywordChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(
              Icons.search,
              size: AppSize.iconMd,
              color: context.colors.textTertiary,
            ),
            // 스피너를 목록 위에 띄우지 않고 칸 안에 둔다. 찾는 동안 아래가
            // 들썩이면 방금 읽던 줄을 놓친다.
            suffixIcon: results.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: SizedBox(
                      width: AppSize.iconSm,
                      height: AppSize.iconSm,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (query.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _Results(
            results: results.value ?? const [],
            tooShort: query.length < placeSearchMinLength,
            loading: results.isLoading,
            onSelect: _select,
          ),
        ],
      ],
    );
  }

  Widget _picked(Place place) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.place_outlined,
            size: AppSize.iconMd,
            color: colors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  place.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: _clear,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }
}

/// 검색 결과 목록.
class _Results extends StatelessWidget {
  const _Results({
    required this.results,
    required this.tooShort,
    required this.loading,
    required this.onSelect,
  });

  final List<Place> results;
  final bool tooShort;
  final bool loading;
  final ValueChanged<Place> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (results.isEmpty) {
      // 찾는 중에 '결과 없음'을 띄우면 방금 없다고 했다가 생기는 꼴이 된다.
      if (loading) return const SizedBox.shrink();

      return _Note(
        tooShort
            ? '$placeSearchMinLength글자 이상 입력하세요'
            : '검색 결과가 없어요. 다른 이름으로 찾아보세요',
      );
    }

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: Container(
        // 목록이 화면을 다 덮으면 아래 칸들이 어디 갔는지 알 수 없다.
        // 넷쯤 보이고 나머지는 밀어서 본다.
        constraints: const BoxConstraints(maxHeight: 240),
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: results.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, thickness: 1, color: colors.border),
          itemBuilder: (context, index) {
            final place = results[index];

            return InkWell(
              onTap: () => onSelect(place),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.bodyMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            place.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    if (place.category != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          place.category!,
                          style: context.texts.labelSmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Text(message, style: context.texts.labelSmall),
    );
  }
}
