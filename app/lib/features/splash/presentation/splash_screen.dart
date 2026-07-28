import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mogacko_logo.dart';

/// 앱 진입 화면.
///
/// 로고를 최소 [_minimumHold] 동안 보여주고, 준비 작업이 그보다 오래 걸리면
/// 끝날 때까지 더 기다린 뒤 다음 화면으로 넘어간다.
///
/// 진입 애니메이션을 일부러 넣지 않는다. 웹에서는 엔진 부팅 전까지
/// web/index.html의 부팅 스플래시가 같은 자리에 같은 로고를 그리고 있어서,
/// 여기서 페이드인을 걸면 두 로고가 교차하며 깜빡이는 것처럼 보인다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// 로고를 붙잡아 두는 최소 시간
  static const _minimumHold = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // 최소 노출과 준비 작업을 나란히 돌려 둘 중 늦은 쪽에 맞춘다.
    await Future.wait([Future<void>.delayed(_minimumHold), _prepare()]);

    if (!mounted) return;
    context.go(AppRoute.login);
  }

  /// 진입 전에 끝나 있어야 하는 준비 작업.
  ///
  /// 저장된 토큰 검증과 세션 복구가 여기에 들어간다. 붙이고 나면 결과에 따라
  /// [_boot]의 목적지를 로그인과 홈으로 나누면 된다.
  Future<void> _prepare() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      // 색은 지정하지 않는다. 라이트는 브랜드 블루, 다크는 흰색으로
      // MogackoLogo가 알아서 고른다.
      body: const Center(child: MogackoLogo.square(size: 112)),
    );
  }
}
