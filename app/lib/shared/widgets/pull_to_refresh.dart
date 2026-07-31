import 'package:flutter/cupertino.dart';

import '../../core/theme/app_theme.dart';

/// 당겨서 새로고침.
///
/// 당긴 만큼 목록이 밀려나고 그 자리에서 스피너가 돈다. 끝나면 목록이 도로
/// 올라온다. 머티리얼 방식처럼 목록 위에 동그라미가 떠 있으면 첫 항목을
/// 가리고, 무엇을 기다리는 중인지가 목록과 겹쳐 보인다.
///
/// 두 가지가 함께 있어야 동작한다.
/// - [CupertinoSliverRefreshControl] 은 슬리버라 [CustomScrollView] 안에만
///   놓인다. 그래서 자식이 아니라 [slivers] 를 받는다.
/// - 당김은 오버스크롤로 감지한다. 안드로이드 기본값(clamping)은 끝에서 더
///   끌리지 않아 아예 당겨지지 않으므로 [BouncingScrollPhysics] 를 세운다.
///   목록의 스크롤 감이 iOS 쪽으로 통일되는데, 이 앱은 탭 바·시트·아이콘이
///   이미 HIG 를 따르고 있어 그쪽이 덜 어긋난다.
///
/// [AlwaysScrollableScrollPhysics] 로 감싸는 이유는 따로 있다. 내용이 화면보다
/// 짧으면 스크롤이 잠겨 당길 수조차 없는데, 정작 당기고 싶은 때가 목록이
/// 비었을 때다.
class PullToRefresh extends StatelessWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.slivers,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: onRefresh,
          builder: (context, mode, pulled, trigger, indicatorExtent) =>
              _Indicator(
                mode: mode,
                pulled: pulled,
                trigger: trigger,
                extent: indicatorExtent,
              ),
        ),
        ...slivers,
      ],
    );
  }
}

/// 당긴 자리에서 도는 표시.
///
/// 당기는 동안에는 얼마나 당겼는지에 맞춰 조금씩 드러나고, 놓는 순간부터
/// 돌기 시작한다. 기본 제공 표시는 회색 고정이라 앱 색과 따로 논다.
class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.mode,
    required this.pulled,
    required this.trigger,
    required this.extent,
  });

  final RefreshIndicatorMode mode;
  final double pulled;
  final double trigger;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = (pulled / trigger).clamp(0.0, 1.0);

    return Center(
      // 열린 자리 안에서 가운데. 자리가 아직 좁을 때 넘치지 않게 잘라 둔다.
      child: SizedBox(
        height: extent,
        child: Center(
          child: switch (mode) {
            // 아직 당기는 중. 기준선에 가까워질수록 살이 붙는다.
            RefreshIndicatorMode.drag => CupertinoActivityIndicator
                .partiallyRevealed(
                  progress: progress,
                  color: colors.textTertiary,
                ),
            // 놓았거나 되감는 중. 실제로 돌아간다.
            RefreshIndicatorMode.inactive || RefreshIndicatorMode.done =>
              const SizedBox.shrink(),
            _ => CupertinoActivityIndicator(color: colors.primary),
          },
        ),
      ),
    );
  }
}
