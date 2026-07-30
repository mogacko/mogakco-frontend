import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 상세 화면의 골격.
///
/// 목록에서 하나를 눌러 들어온 화면들이 같은 뼈대를 쓴다. 뒤로 가기 위치와
/// 본문 여백이 화면마다 달라지면 들어갈 때마다 눈이 다시 자리를 찾는다.
///
/// 결정 버튼([bottomAction])은 아래에 붙여 둔다. 본문이 길어도 스크롤을 끝까지
/// 내리지 않고 결정할 수 있어야 한다.
class DetailScaffold extends StatelessWidget {
  const DetailScaffold({
    super.key,
    required this.children,
    this.title,
    this.actions = const [],
    this.bottomAction,
  });

  /// 스크롤되는 본문. 좌우 여백은 각 조각이 알아서 맞춘다.
  final List<Widget> children;

  /// 상단 바에 적을 이름. 없으면 뒤로 가기만 둔다.
  ///
  /// 제목을 여기 또 적지 않는 화면이 많다. 본문 첫 줄이 이미 제목이라
  /// 위아래로 같은 말이 겹친다.
  final String? title;

  final List<Widget> actions;

  /// 화면 아래에 붙는 결정 버튼. 없으면 본문만 놓인다.
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = this.title;
    final bottomAction = this.bottomAction;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal - AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.screenHorizontal - AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _BackButton(),
                  if (title != null)
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleLarge,
                      ),
                    )
                  else
                    const Spacer(),
                  ...actions,
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.huge),
                children: children,
              ),
            ),
            if (bottomAction != null)
              // 버튼이 본문 위에 떠 있는 게 아니라 화면 바닥에 붙는다.
              // 위에 선을 한 줄 둬서 본문이 그 아래로 이어지지 않는다는 걸 알린다.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.background,
                  border: Border(
                    top: BorderSide(color: colors.border, width: 0.5),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                      AppSpacing.screenHorizontal,
                      AppSpacing.md,
                    ),
                    child: bottomAction,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 뒤로 가기.
///
/// [BackButton] 은 48x48 을 차지해 상단 바를 두껍게 만든다. 다른 헤더의
/// 아이콘 버튼과 같은 규격으로 맞춘다.
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '뒤로',
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            CupertinoIcons.chevron_back,
            size: AppSize.iconMd,
            color: context.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
