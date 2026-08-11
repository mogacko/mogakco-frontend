import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 아무것도 못 받았을 때 세우는 화면.
///
/// 빈 상태([EmptyState])와 다르다. 그쪽은 '아직 아무 일도 일어나지 않았다'라
/// 무엇을 하면 채워지는지 알려주면 되지만, 여기는 '있는데 못 가져왔다'라
/// 사용자가 할 일은 다시 시도하는 것 하나다.
///
/// 둘을 같은 화면으로 두면 서버가 죽었을 때 '첫 글을 남겨보세요'가 뜬다.
class LoadFailure extends StatelessWidget {
  const LoadFailure({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;

  /// 무엇을 못 받았는지. 없으면 일반 문구.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.huge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.wifi_slash,
              size: AppSize.iconMd,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message ?? '불러오지 못했어요',
            textAlign: TextAlign.center,
            style: context.texts.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            // 원인을 단정하지 않는다. 서버가 죽었는지 전파가 약한지 앱은
            // 가릴 수 없고, 사용자가 할 일은 어느 쪽이든 같다.
            '연결을 확인하고 다시 시도해 주세요',
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
