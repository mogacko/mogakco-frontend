import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'safety_provider.dart';

/// 차단한 사람들.
///
/// 차단은 상세 화면 안쪽에서 하지만 푸는 자리는 여기다. 차단하고 나면 그
/// 사람 글이 안 보이는데, 푸는 길이 그 안에만 있으면 되돌릴 방법이 없다.
class BlockedMembersScreen extends ConsumerWidget {
  const BlockedMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedProvider).toList()..sort();

    return DetailScaffold(
      title: '차단한 사람',
      children: [
        if (blocked.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.huge),
            child: EmptyState(
              icon: CupertinoIcons.nosign,
              title: '차단한 사람이 없어요',
              description: '불편한 사람을 만나면 프로필에서 차단할 수 있어요',
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              0,
              AppSpacing.screenHorizontal,
              AppSpacing.lg,
            ),
            child: Text(
              '차단한 사람의 글과 댓글은 보이지 않고, 그 사람도 회원님의 프로필을 볼 수 없어요',
              style: context.texts.labelSmall,
            ),
          ),
          for (final id in blocked)
            _BlockedRow(
              id: id,
              onUnblock: () {
                Haptics.toggle();
                ref.read(blockedProvider.notifier).unblock(id);
              },
            ),
        ],
      ],
    );
  }
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({required this.id, required this.onUnblock});

  final String id;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          UserAvatar(name: id, size: 36),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodyLarge?.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onUnblock,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('차단 해제'),
          ),
        ],
      ),
    );
  }
}
