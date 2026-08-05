import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/haptics.dart';
import '../../../../shared/widgets/user_avatar.dart';

/// 내보내면서 함께 정한 것.
typedef KickChoice = ({bool alsoBlock});

/// 참여자를 내보낼지 묻는다. 차단까지 한 번에 정한다.
///
/// 내보내고 나서 차단을 따로 찾아 들어가게 두지 않는다. 내보내는 순간이 그
/// 사람을 어떻게 할지 정하는 순간이고, 그때를 놓치면 대개 그냥 넘어간다.
///
/// 두 가지는 다른 일이다. 내보내기는 이 모임에서만 빼는 것이고, 차단은 앱
/// 전체에서 안 보이게 하는 것이다. 그래서 차단은 켜 두지 않고 고르게 한다.
Future<KickChoice?> showKickSheet(
  BuildContext context, {
  required String name,
  required int dayCount,
}) {
  return showModalBottomSheet<KickChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _KickSheet(name: name, dayCount: dayCount),
  );
}

class _KickSheet extends StatefulWidget {
  const _KickSheet({required this.name, required this.dayCount});

  final String name;

  /// 이 사람이 오기로 한 날 수. 둘 이상이면 한 번에 다 빠진다고 알린다.
  final int dayCount;

  @override
  State<_KickSheet> createState() => _KickSheetState();
}

class _KickSheetState extends State<_KickSheet> {
  bool _alsoBlock = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  UserAvatar(name: widget.name, size: 40),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.name}님을 내보낼까요?',
                          style: context.texts.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.dayCount > 1
                              ? '오기로 한 ${widget.dayCount}일이 모두 취소되고, 이 모각코에 다시 신청할 수 없어요'
                              : '이 모각코에 다시 신청할 수 없어요',
                          style: context.texts.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            // 차단은 다른 일이다. 켜 둔 채로 두면 내보내려던 사람이 앱 전체에서
            // 사라진 것을 나중에 알게 된다.
            SwitchListTile.adaptive(
              value: _alsoBlock,
              onChanged: (value) {
                Haptics.toggle();
                setState(() => _alsoBlock = value);
              },
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xs,
              ),
              title: Text(
                '${widget.name}님 차단하기',
                style: context.texts.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '다른 모임과 커뮤니티에서도 이 사람의 글이 보이지 않아요',
                  style: context.texts.labelSmall,
                ),
              ),
            ),
            Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: () {
                      Haptics.decide();
                      Navigator.of(context).pop((alsoBlock: _alsoBlock));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.danger,
                    ),
                    child: const Text('내보내기'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('그대로 두기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
