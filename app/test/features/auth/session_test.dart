import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mogacko/app.dart';
import 'package:mogacko/core/router/app_router.dart';
import 'package:mogacko/features/auth/presentation/login_screen.dart';
import 'package:mogacko/features/auth/presentation/session_provider.dart';
import 'package:mogacko/features/shell/presentation/app_shell.dart';
import 'package:mogacko/shared/domain/chapter.dart';

/// 로그인 상태가 화면을 가르는지 본다.
///
/// 이동을 화면마다 손으로 적으면 언젠가 어긋난다. 세션 하나만 바꿔도 라우터가
/// 알아서 옮겨 주는지가 여기서 확인된다.
void main() {
  /// 앱을 띄우고 스플래시 타이머를 흘려보낸다.
  Future<ProviderContainer> boot(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MogackoApp()),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('로그인하지 않았으면 로그인 화면에 선다', (tester) async {
    await boot(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('로그인하면 홈으로 옮겨진다', (tester) async {
    final container = await boot(tester);

    container.read(sessionProvider.notifier).signIn(chapter: Chapter.seoul);
    await tester.pumpAndSettle();

    // 화면이 직접 옮기지 않는다. 세션이 차면 라우터가 옮긴다.
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('로그아웃하면 로그인 화면으로 돌아온다', (tester) async {
    final container = await boot(tester);
    container.read(sessionProvider.notifier).signIn(chapter: Chapter.seoul);
    await tester.pumpAndSettle();

    container.read(sessionProvider.notifier).signOut();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('로그인한 채로 가입 화면에 가려 하면 홈으로 되돌린다', (tester) async {
    final container = await boot(tester);
    container.read(sessionProvider.notifier).signIn(chapter: Chapter.seoul);
    await tester.pumpAndSettle();

    // 브라우저 뒤로가기로 가입 완료에 돌아가는 경우가 이 길로 온다. 라우트
    // 스택은 비었는데 브라우저 히스토리에는 항목이 남아 생기는 일이다.
    final ctx = tester.element(find.byType(Navigator).first);
    ctx.go(AppRoute.signupComplete);
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
  });

  test('계정 지역은 가입 때 고른 것을 따른다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(signupChapterProvider.notifier).select(Chapter.busan);
    container.read(sessionProvider.notifier).signIn(
      chapter: container.read(signupChapterProvider)!,
    );

    expect(container.read(sessionProvider)?.chapter, Chapter.busan);
  });
}
