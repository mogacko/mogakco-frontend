import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 마우스로도 끌어서 넘길 수 있게 하는 스크롤 동작.
///
/// Flutter는 기본적으로 터치·스타일러스·트랙패드만 드래그로 받는다
/// (scroll_configuration.dart 의 _kTouchLikeDeviceTypes). 그대로 두면
/// 웹에서 마우스로 캐러셀을 밀 수 없어 화살표 버튼을 따로 둬야 한다.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}
