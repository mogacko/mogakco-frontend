import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 탭 첫 줄에 놓는 큰 제목.
///
/// 지금 어느 탭에 있는지는 탭 바 아이콘만으로는 흐리다. iOS 앱들이 화면 맨
/// 위에 큰 제목을 두는 이유가 그것이고, 여기서도 탭마다 같은 자리·같은 크기로
/// 세워 화면을 오갈 때 제목만 갈리게 한다.
///
/// 홈만 예외로 제목 대신 지역 워드마크를 세운다. 홈에서는 화면 이름보다
/// 어느 지역을 보고 있는지가 먼저 필요해서다.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required String this.title, this.actions = const []})
    : titleWidget = null;

  /// 제목 자리에 위젯을 직접 세운다.
  ///
  /// 커뮤니티처럼 제목이 곧 전환 버튼인 화면에 쓴다. 제목 글자 크기와 여백은
  /// 세우는 쪽에서 맞춘다.
  const ScreenHeader.custom({
    super.key,
    required Widget this.titleWidget,
    this.actions = const [],
  }) : title = null;

  final String? title;
  final Widget? titleWidget;

  /// 오른쪽 끝에 붙는 [HeaderAction] 들
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final titleWidget = this.titleWidget;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        // 아이콘 버튼이 자체 여백을 갖고 있어 그만큼 당겨야
        // 아이콘 중심이 아니라 가장자리가 본문 여백과 맞는다.
        AppSpacing.screenHorizontal - AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (titleWidget != null) ...[
            // 누를 수 있는 제목은 글자만큼만 차지해야 옆 빈자리까지 눌리지
            // 않는다. 남는 폭은 Spacer 가 가져간다.
            titleWidget,
            const Spacer(),
          ] else
            Expanded(
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.headlineLarge,
              ),
            ),
          ...actions,
        ],
      ),
    );
  }
}

/// 헤더 오른쪽 끝의 아이콘 버튼.
///
/// [IconButton] 은 48x48 터치 영역을 차지해 헤더를 그만큼 두껍게 만든다.
/// 손가락이 닿을 만큼만 남기고 직접 그린다.
class HeaderAction extends StatelessWidget {
  const HeaderAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;

  /// 스크린 리더가 읽을 이름. 아이콘만으로는 뜻이 전달되지 않는다.
  final String label;

  final VoidCallback onTap;

  /// 그 화면에서 가장 권하는 행동인지. 켜면 브랜드 색으로 올라온다.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: AppSize.iconMd,
            color: emphasized ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
