import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/haptics.dart';
import '../../../../shared/widgets/form_field_block.dart';
import '../../domain/poster.dart';
import 'poster_image.dart';

/// 포스터를 고르는 칸.
///
/// 없어도 올릴 수 있다. 지부가 매번 포스터를 만들지는 않고, 필수로 두면
/// 그림 만들 시간이 없다는 이유로 행사가 안 올라온다.
class PosterPickerField extends StatefulWidget {
  const PosterPickerField({
    super.key,
    required this.poster,
    required this.onChanged,
  });

  final Poster? poster;
  final ValueChanged<Poster?> onChanged;

  @override
  State<PosterPickerField> createState() => _PosterPickerFieldState();
}

class _PosterPickerFieldState extends State<PosterPickerField> {
  /// 고르는 동안. 큰 사진은 읽어 들이는 데 잠깐 걸린다.
  bool _picking = false;

  /// 원본을 그대로 들고 있지 않는다. 요즘 폰 사진은 한 장에 5MB가 넘어서,
  /// 메모리에 올려둔 채 폼을 채우다 보면 웹에서 특히 버겁다. 포스터는 화면
  /// 폭보다 클 이유가 없다.
  static const _maxWidth = 1440.0;
  static const _quality = 85;

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxWidth,
        imageQuality: _quality,
      );
      if (picked == null) return;

      // 경로가 아니라 바이트로 읽는다. 웹에서는 경로가 blob 주소라 앱과
      // 다르게 다뤄야 하는데, 바이트는 어느 쪽에서도 같다.
      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      Haptics.toggle();
      widget.onChanged(LocalPoster(bytes));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poster = widget.poster;

    return FormFieldBlock(
      label: '포스터',
      optional: true,
      hint: '없으면 목록에서 날짜 칸으로 대신 보여요',
      child: poster == null
          ? _Empty(picking: _picking, onTap: _pick)
          : _Picked(
              poster: poster,
              onReplace: _pick,
              onRemove: () => widget.onChanged(null),
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.picking, required this.onTap});

  final bool picking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: picking ? null : onTap,
        child: SizedBox(
          // 상세에서 4:3으로 세운다. 고르는 자리도 같은 비율이어야 어디가
          // 잘릴지 미리 안다.
          height: 120,
          width: double.infinity,
          child: Center(
            child: picking
                ? const SizedBox(
                    width: AppSize.iconMd,
                    height: AppSize.iconMd,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.photo,
                        size: AppSize.iconMd,
                        color: colors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('포스터 고르기', style: context.texts.labelSmall),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Picked extends StatelessWidget {
  const _Picked({
    required this.poster,
    required this.onReplace,
    required this.onRemove,
  });

  final Poster poster;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AspectRatio(
            // 상세와 같은 비율로 미리 보여준다. 여기서 멀쩡해 보이던 글자가
            // 올리고 나서 잘려 있으면 다시 만들어야 한다.
            aspectRatio: 4 / 3,
            child: PosterImage(poster: poster),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReplace,
                child: const Text('다른 그림'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: onRemove,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.danger,
                ),
                child: const Text('빼기'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
