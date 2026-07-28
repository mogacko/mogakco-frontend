import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mogacko/core/theme/app_theme.dart';

extension PumpApp on WidgetTester {
  /// 화면 하나를 앱 테마와 라우터 컨텍스트 안에서 띄운다.
  ///
  /// 화면들이 `context.push`를 쓰기 때문에 GoRouter가 조상에 있어야 한다.
  /// 전역 라우터를 그대로 쓰면 테스트끼리 이동 이력이 섞여서 매번 새로 만든다.
  Future<void> pumpScreen(
    Widget screen, {
    Brightness brightness = Brightness.light,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => screen),
        // 이동 대상이 없으면 탭·타이머 테스트가 예외로 죽는다.
        // 실제 경로와 이름을 맞춰 스플래시의 자동 이동까지 받아낸다.
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('login-landed')),
        ),
        GoRoute(
          path: '/signup/terms',
          builder: (_, _) => const Scaffold(body: Text('terms-landed')),
        ),
        GoRoute(
          path: '/signup/chapter',
          builder: (_, _) => const Scaffold(body: Text('chapter-landed')),
        ),
        GoRoute(
          path: '/signup/profile',
          builder: (_, _) => const Scaffold(body: Text('profile-landed')),
        ),
        GoRoute(
          path: '/signup/complete',
          builder: (_, _) => const Scaffold(body: Text('complete-landed')),
        ),
      ],
    );

    await pumpWidget(
      MaterialApp.router(
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        routerConfig: router,
      ),
    );
  }
}
