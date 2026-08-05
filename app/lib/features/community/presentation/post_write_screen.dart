import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/utils/navigation.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/form_field_block.dart';
import '../../auth/presentation/session_provider.dart';
import '../domain/post.dart';
import 'post_provider.dart';

/// 글을 쓴다.
///
/// 게시판은 들어올 때 보고 있던 것으로 정해진다. 질문 게시판에서 글쓰기를
/// 눌렀는데 자유로 열리면 한 번 더 고쳐야 한다. 공지는 운영진만 올리므로
/// 여기로 올 길이 아예 없다.
class PostWriteScreen extends ConsumerStatefulWidget {
  const PostWriteScreen({super.key, required this.board, this.postId});

  final PostBoard board;

  /// 고칠 글의 id. 없으면 새로 쓰는 것이다.
  ///
  /// 쓰기와 고치기를 한 화면으로 둔다. 나눠 두면 칸이 하나 늘 때마다 두 곳을
  /// 맞춰야 하고, 한쪽만 고쳐 두면 고칠 때만 없는 칸이 생긴다.
  final String? postId;

  @override
  ConsumerState<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends ConsumerState<PostWriteScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  /// 이야기 게시판에서만 고른다. 다른 게시판은 그 자체로 분류다.
  PostCategory _category = PostCategory.free;

  bool get _isEditing => widget.postId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.postId;
    if (id == null) return;

    // 지금 값으로 칸을 채워 연다. 빈 폼을 주면 안 고칠 것까지 다시 적어야 한다.
    final post = ref
        .read(postFeedProvider)
        .where((post) => post.id == id)
        .firstOrNull;
    if (post == null) return;

    _title.text = post.title;
    _body.text = post.body;
    _category = post.category ?? PostCategory.free;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;

  void _submit() {
    final id = widget.postId;
    if (id != null) {
      ref
          .read(postFeedProvider.notifier)
          .edit(
            id,
            title: _title.text.trim(),
            body: _body.text.trim(),
            category: _category,
          );
      Haptics.decide();
      goBack(context);
      return;
    }

    final now = ref.read(nowProvider);
    final session = ref.read(sessionProvider);

    final post = Post(
      id: '${PostFeed.localPrefix}${now.microsecondsSinceEpoch}',
      chapter: ref.read(currentChapterProvider),
      board: widget.board,
      category: widget.board.hasCategories ? _category : null,
      title: _title.text.trim(),
      body: _body.text.trim(),
      author: session?.nickname ?? '나',
      createdAt: now,
      likeCount: 0,
    );

    ref.read(postFeedProvider.notifier).add(post);
    Haptics.decide();
    // 목록으로 돌아가지 않고 방금 쓴 글로 들어간다. 올라간 모양을 바로
    // 확인할 수 있고, 잘못 적었으면 그 자리에서 안다.
    context.pushReplacement(AppRoute.post(post.id));
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;

    return DetailScaffold(
      title: _isEditing ? '글 고치기' : '${board.label} 글쓰기',
      bottomAction: FilledButton(
        onPressed: _canSubmit ? _submit : null,
        child: Text(_isEditing ? '저장' : '올리기'),
      ),
      children: [
        if (board.hasCategories) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Text(
              '분류',
              style: context.texts.labelMedium?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // 목록의 필터와 같은 알약을 쓴다. 고르는 값이 같은데 모양이 다르면
          // 둘이 다른 것인 줄 안다.
          FilterBar<PostCategory>(
            options: PostCategory.values,
            selected: _category,
            labelOf: (category) => category.label,
            onSelect: (category) => setState(() => _category = category),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormFieldBlock(
                label: '제목',
                child: TextField(
                  controller: _title,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.next,
                  maxLength: 60,
                  decoration: InputDecoration(
                    hintText: switch (board) {
                      PostBoard.question => '무엇이 막히시나요?',
                      _ => '무슨 이야기인가요?',
                    },
                    // 글자 수는 거의 다 찼을 때만 쓸모가 있다. 늘 띄워 두면
                    // 제목 칸마다 숫자가 하나씩 붙는다.
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormFieldBlock(
                label: '내용',
                child: TextField(
                  controller: _body,
                  onChanged: (_) => setState(() {}),
                  minLines: 8,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: switch (board) {
                      PostBoard.question =>
                        '무엇을 해봤고 어디서 막혔는지 적으면 답이 빨리 옵니다',
                      _ => '편하게 적어주세요',
                    },
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
