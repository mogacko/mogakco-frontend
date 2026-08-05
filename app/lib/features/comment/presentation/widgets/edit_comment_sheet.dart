import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/haptics.dart';

/// 댓글을 고치는 시트.
///
/// 화면을 새로 열지 않는다. 댓글은 한두 줄이라 화면을 통째로 옮기면 오가는
/// 품이 고치는 일보다 커진다.
Future<String?> showEditCommentSheet(
  BuildContext context, {
  required String initial,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditCommentSheet(initial: initial),
  );
}

class _EditCommentSheet extends StatefulWidget {
  const _EditCommentSheet({required this.initial});

  final String initial;

  @override
  State<_EditCommentSheet> createState() => _EditCommentSheetState();
}

class _EditCommentSheetState extends State<_EditCommentSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 비우는 건 지우는 것과 다르다. 지우려면 삭제가 따로 있다.
  bool get _canSave {
    final body = _controller.text.trim();
    return body.isNotEmpty && body != widget.initial.trim();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('댓글 고치기', style: context.texts.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                maxLength: 300,
                decoration: const InputDecoration(counterText: ''),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _canSave
                    ? () {
                        Haptics.decide();
                        Navigator.of(context).pop(_controller.text.trim());
                      }
                    : null,
                child: const Text('저장'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
