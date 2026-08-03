import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/utils/navigation.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../comment/presentation/comment_provider.dart';
import 'post_provider.dart';
import 'widgets/post_card.dart';

/// 글 검색.
///
/// 게시판을 가리지 않고 지금 지역의 글 전체에서 찾는다. 찾는 사람은 그게 어느
/// 게시판에 있었는지까지 기억하고 오지 않는다.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = ref.watch(nowProvider);
    final commentCounts = ref.watch(postCommentCountsProvider);
    final results = ref.watch(searchedPostsProvider(_query));
    final query = _query.trim();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SearchBar(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              onClear: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
            Expanded(
              child: switch ((query.isEmpty, results.isEmpty)) {
                // 아직 아무것도 안 쳤다. 빈 화면에 안내를 세우지 않고 그냥
                // 비워 둔다 — 키보드가 이미 올라와 있어 무엇을 할 자리인지
                // 더 말할 필요가 없다.
                (true, _) => const SizedBox.shrink(),
                (false, true) => Center(
                  child: EmptyState(
                    icon: CupertinoIcons.search,
                    title: '\'$query\' 검색 결과가 없어요',
                    description: '다른 낱말로 찾아보세요',
                  ),
                ),
                (false, false) => ColoredBox(
                  color: colors.surface,
                  child: ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    itemCount: results.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, thickness: 1, color: colors.border),
                    itemBuilder: (context, index) {
                      final post = results[index];

                      return PostCard(
                        post: post,
                        now: now,
                        commentCount: commentCounts[post.id] ?? 0,
                        showBoard: true,
                        onToggleLike: () => ref
                            .read(postFeedProvider.notifier)
                            .toggleLike(post.id),
                        onTap: () => context.push(AppRoute.post(post.id)),
                      );
                    },
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 뒤로 가기와 입력칸을 한 줄에 놓은 헤더.
///
/// 화면 제목을 따로 두지 않는다. 검색은 들어오자마자 치는 화면이라 '검색'이라
/// 적힌 줄이 하나 더 있으면 입력칸이 그만큼 아래로 밀린다.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => goBack(context),
            icon: const Icon(CupertinoIcons.chevron_back),
            iconSize: AppSize.iconMd,
            color: colors.textPrimary,
            tooltip: '뒤로',
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '제목, 내용, 글쓴이로 찾기',
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  size: AppSize.iconSm,
                  color: colors.textTertiary,
                ),
                suffixIcon: ValueListenableBuilder(
                  valueListenable: controller,
                  builder: (context, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: onClear,
                          icon: const Icon(
                            CupertinoIcons.clear_circled_solid,
                          ),
                          iconSize: AppSize.iconSm,
                          color: colors.textTertiary,
                          tooltip: '지우기',
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
