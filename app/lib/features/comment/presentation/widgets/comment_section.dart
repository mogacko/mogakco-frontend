import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/relative_time.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../safety/domain/report.dart';
import '../../../safety/presentation/widgets/safety_menu.dart';
import '../../domain/comment.dart';

/// 댓글 목록.
///
/// 단 순서대로 위에서 아래로 읽는다. 대화라서 최신순으로 뒤집으면 답이 질문
/// 위에 온다.
class CommentSection extends StatelessWidget {
  const CommentSection({
    super.key,
    required this.comments,
    required this.now,
    required this.onDelete,
  });

  final List<Comment> comments;
  final DateTime now;
  final void Function(Comment comment) onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Text(
            // 개수를 제목에 붙인다. 아래 목록을 세지 않아도 몇 개인지 알 수 있다.
            '댓글 ${comments.length}',
            style: context.texts.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.xl,
            ),
            child: Text(
              '첫 댓글을 남겨보세요',
              style: context.texts.bodyMedium?.copyWith(
                color: colors.textTertiary,
              ),
            ),
          )
        else
          for (final comment in comments)
            _CommentTile(
              comment: comment,
              now: now,
              onDelete: () => onDelete(comment),
            ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.now,
    required this.onDelete,
  });

  final Comment comment;
  final DateTime now;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: comment.author,
            imageUrl: comment.authorAvatarUrl,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: context.texts.labelMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      relativeTime(comment.createdAt, now),
                      style: context.texts.labelSmall,
                    ),
                    const Spacer(),
                    // 내가 쓴 것만 지울 수 있다. 남의 댓글에 지우기 버튼이
                    // 보이면 눌러보고 나서야 안 된다는 걸 알게 된다.
                    if (comment.isMine)
                      Semantics(
                        button: true,
                        label: '댓글 삭제',
                        child: InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 13,
                              color: colors.textTertiary,
                            ),
                          ),
                        ),
                      )
                    else
                      // 남의 댓글에는 지우기 대신 신고를 둔다. 같은 자리에
                      // 아무것도 없으면 불편한 댓글을 만났을 때 할 수 있는
                      // 게 없다.
                      Consumer(
                        builder: (context, ref, _) => Semantics(
                          button: true,
                          label: '댓글 신고',
                          child: InkWell(
                            onTap: () => showSafetySheet(
                              context,
                              ref,
                              target: ReportTarget.comment,
                              targetId: comment.id,
                              memberId: comment.author,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: Icon(
                                CupertinoIcons.ellipsis,
                                size: 13,
                                color: colors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.body, style: context.texts.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 댓글 입력줄.
///
/// 화면 아래에 붙는다. 긴 글을 다 읽고 나서 쓰게 되는데, 그때 맨 아래까지
/// 내려가 입력란을 찾게 두지 않는다.
class CommentField extends StatefulWidget {
  const CommentField({super.key, required this.onSubmit});

  final void Function(String body) onSubmit;

  @override
  State<CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends State<CommentField> {
  final _controller = TextEditingController();

  /// 빈 칸일 때는 보내기를 잠근다.
  bool get _canSend => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _submit() {
    if (!_canSend) return;
    widget.onSubmit(_controller.text);
    _controller.clear();
    // 이어서 더 쓰는 경우가 드물어 키보드를 내린다.
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '댓글을 남겨주세요',
              // 입력줄이 한 줄짜리라 기본 높이는 지나치게 두껍다.
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Semantics(
          button: true,
          label: '댓글 보내기',
          child: Material(
            color: _canSend ? colors.primary : colors.surfaceAlt,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _canSend ? _submit : null,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Icon(
                  CupertinoIcons.arrow_up,
                  size: AppSize.iconSm,
                  color: _canSend
                      ? colors.primaryForeground
                      : colors.textTertiary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
