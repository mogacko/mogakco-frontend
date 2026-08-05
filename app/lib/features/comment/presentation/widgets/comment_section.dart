import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/relative_time.dart';
import '../../../../shared/widgets/owner_menu.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../safety/domain/report.dart';
import '../../../safety/presentation/widgets/safety_menu.dart';
import '../../domain/comment.dart';
import '../comment_provider.dart';

/// 댓글 목록.
///
/// 단 순서대로 위에서 아래로 읽는다. 대화라서 최신순으로 뒤집으면 답이 질문
/// 위에 온다.
///
/// 답글은 부모 밑에 한 단계만 들여 쓴다. 답글에 답글을 달면 같은 스레드 맨
/// 아래에 붙는다 — 모바일 폭에서 3단계째는 한 줄에 몇 글자 못 들어간다.
class CommentSection extends StatefulWidget {
  const CommentSection({
    super.key,
    required this.nodes,
    required this.count,
    required this.now,
    required this.onDelete,
    required this.onEdit,
    required this.onReply,
  });

  final List<CommentNode> nodes;

  /// 제목에 붙일 개수. 지워진 자리는 빼고 센다.
  final int count;

  final DateTime now;
  final void Function(Comment comment) onDelete;
  final void Function(Comment comment) onEdit;
  final void Function(Comment parent, String body) onReply;

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  /// 지금 답글을 쓰고 있는 부모 댓글의 id.
  ///
  /// 아래 고정 입력줄로 받지 않고 그 자리에 연다. 어디에 달리는 답글인지가
  /// 위치로 드러나야, 화면 아래에 '누구에게'라고 또 적지 않아도 된다.
  String? _replyingTo;

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
            '댓글 ${widget.count}',
            style: context.texts.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.nodes.isEmpty)
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
          for (final node in widget.nodes) ...[
            if (node.masked)
              _MaskedTile(hasReplies: node.replies.isNotEmpty)
            else
              _CommentTile(
                comment: node.comment,
                now: widget.now,
                onDelete: () => widget.onDelete(node.comment),
                onEdit: () => widget.onEdit(node.comment),
              ),
            for (final reply in node.replies)
              _CommentTile(
                comment: reply,
                now: widget.now,
                isReply: true,
                onDelete: () => widget.onDelete(reply),
                onEdit: () => widget.onEdit(reply),
              ),
            if (_replyingTo == node.comment.id)
              _ReplyComposer(
                onCancel: () => setState(() => _replyingTo = null),
                onSubmit: (body) {
                  widget.onReply(node.comment, body);
                  setState(() => _replyingTo = null);
                },
              )
            else
              _ReplyButton(
                onTap: () => setState(() => _replyingTo = node.comment.id),
              ),
          ],
      ],
    );
  }
}

/// 답글이 들여 쓰이는 폭. 아바타(28) + 사이(12).
const _replyIndent = 40.0;

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.now,
    required this.onDelete,
    required this.onEdit,
    this.isReply = false,
  });

  final Comment comment;
  final DateTime now;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal + (isReply ? _replyIndent : 0),
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: comment.author,
            imageUrl: comment.authorAvatarUrl,
            // 답글은 조금 작게. 들여쓰기만으로는 한 화면에 여러 스레드가
            // 겹칠 때 어느 쪽이 부모인지 흐려진다.
            size: isReply ? 24 : 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 남는 폭을 왼쪽 묶음이 통째로 가져간다. Flexible 과
                    // Spacer 를 한 줄에 같이 두면 flex 가 1대1이라 빈 폭을
                    // 반씩 나눠 갖고, '⋯'가 오른쪽 끝이 아니라 가운데쯤 선다.
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              comment.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.labelMedium?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            relativeTime(comment.createdAt, now),
                            style: context.texts.labelSmall,
                          ),
                          if (comment.isEdited) ...[
                            const SizedBox(width: AppSpacing.xs),
                            // 고친 댓글에는 표를 붙인다. 이어지던 대화가
                            // 갑자기 어긋나 보일 때 그 이유를 알 수 있어야 한다.
                            Text('수정됨', style: context.texts.labelSmall),
                          ],
                        ],
                      ),
                    ),
                    // 내 것에는 고치기·삭제, 남의 것에는 신고. 같은 자리·같은
                    // 모양이라 버튼이 옮겨 다니지 않는다.
                    if (comment.isMine)
                      _TileMenu(
                        label: '내 댓글 더보기',
                        onTap: () async {
                          final action = await showOwnerSheet(
                            context,
                            what: '댓글',
                            deleteTitle: '이 댓글을 삭제할까요?',
                            deleteDescription: '되돌릴 수 없어요.',
                          );
                          switch (action) {
                            case OwnerAction.edit:
                              onEdit();
                            case OwnerAction.delete:
                              onDelete();
                            case null:
                              break;
                          }
                        },
                      )
                    else
                      Consumer(
                        builder: (context, ref, _) => _TileMenu(
                          label: '댓글 신고',
                          onTap: () => showSafetySheet(
                            context,
                            ref,
                            target: ReportTarget.comment,
                            targetId: comment.id,
                            memberId: comment.author,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.body,
                  style: context.texts.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileMenu extends StatelessWidget {
  const _TileMenu({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(
            CupertinoIcons.ellipsis,
            size: 13,
            color: context.colors.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// 지워졌거나 가려진 댓글의 자리.
///
/// 답글이 달려 있어서 없앨 수 없는 자리다. 없애 버리면 밑에 달린 답글이
/// 무슨 말에 대한 것인지 알 수 없게 된다.
class _MaskedTile extends StatelessWidget {
  const _MaskedTile({required this.hasReplies});

  final bool hasReplies;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      child: Text(
        hasReplies ? '삭제된 댓글이에요' : '볼 수 없는 댓글이에요',
        style: context.texts.bodyMedium?.copyWith(
          color: context.colors.textTertiary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

/// 스레드 끝에 놓는 '답글' 한 줄.
class _ReplyButton extends StatelessWidget {
  const _ReplyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenHorizontal + _replyIndent,
        bottom: AppSpacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              '답글',
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 그 자리에서 여는 답글 입력칸.
class _ReplyComposer extends StatefulWidget {
  const _ReplyComposer({required this.onSubmit, required this.onCancel});

  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  @override
  State<_ReplyComposer> createState() => _ReplyComposerState();
}

class _ReplyComposerState extends State<_ReplyComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal + _replyIndent,
        0,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              maxLength: 300,
              style: context.texts.bodyMedium?.copyWith(
                color: colors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '답글을 남겨주세요',
                counterText: '',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: '답글 등록',
            child: IconButton(
              onPressed: _canSubmit
                  ? () => widget.onSubmit(_controller.text)
                  : null,
              icon: const Icon(CupertinoIcons.arrow_up),
              iconSize: AppSize.iconSm,
              color: colors.primary,
            ),
          ),
          Semantics(
            button: true,
            label: '답글 취소',
            child: IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(CupertinoIcons.xmark),
              iconSize: AppSize.iconSm,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 화면 아래에 붙는 댓글 입력줄.
///
/// 여기서 쓴 것은 늘 새 댓글이다. 답글은 스레드 안에서 그 자리에 연다.
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
