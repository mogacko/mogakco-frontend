import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mogacko/app.dart';
import 'package:mogacko/core/router/app_router.dart';
import 'package:mogacko/features/auth/presentation/session_provider.dart';
import 'package:mogacko/features/community/presentation/post_detail_screen.dart';
import 'package:mogacko/features/signup/domain/term.dart';
import 'package:mogacko/features/shell/presentation/app_shell.dart';
import 'package:mogacko/shared/domain/chapter.dart';
import 'package:mogacko/shared/widgets/app_bottom_nav.dart';

/// 상세를 열면 주소가 바뀌는지 본다.
///
/// 네이티브는 Navigator 스택으로 되돌아가지만 웹과 PWA 는 주소를 기준으로
/// 움직인다. 주소가 안 바뀌면 뒤로가기가 상세를 건너뛰고 그 이전 화면으로
/// 가버린다. iOS 를 PWA 로 쓰는 동안은 그게 곧 실사용이다.
void main() {
  /// 로그인한 채로 앱을 띄운다.
  Future<(ProviderContainer, GoRouter)> boot(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).signIn(chapter: Chapter.busan);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MogackoApp()),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    return (container, container.read(routerProvider));
  }

  /// 지금 화면이 가리키는 주소.
  ///
  /// currentConfiguration.uri 는 push 로 올린 것을 담지 못한다. 맨 위 항목을
  /// 봐야 상세까지 잡힌다 — 웹 주소창에 찍히는 것도 이쪽이다.
  String locationOf(GoRouter router) => router.state.uri.toString();

  testWidgets('글을 열면 주소가 그 글을 가리킨다', (tester) async {
    final (_, router) = await boot(tester);
    expect(locationOf(router), AppRoute.home);

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('커뮤니티'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('3개월 만에 첫 사이드'));
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailScreen), findsOneWidget);
    expect(locationOf(router), '/post/busan-t1');
  });

  testWidgets('뒤로 가면 상세만 닫히고 목록에 남는다', (tester) async {
    final (_, router) = await boot(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('커뮤니티'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('3개월 만에 첫 사이드'));
    await tester.pumpAndSettle();

    // 웹에서는 브라우저 뒤로가기가, 네이티브에서는 스와이프가 이 자리에 온다.
    final ctx = tester.element(find.byType(PostDetailScreen));
    Navigator.of(ctx).pop();
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
    // 한 번 물러났을 뿐인데 두 칸 밀리면 안 된다.
    expect(locationOf(router), AppRoute.home);
  });

  testWidgets('주소로 바로 들어가도 그 글이 열린다', (tester) async {
    final (_, router) = await boot(tester);

    // 새로고침이나 알림에서 오는 길이다.
    router.go('/post/busan-t1');
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailScreen), findsOneWidget);
  });

  testWidgets('로그인하지 않았으면 상세 주소로도 못 들어간다', (tester) async {
    final (container, router) = await boot(tester);
    container.read(sessionProvider.notifier).signOut();
    await tester.pumpAndSettle();

    router.go('/post/busan-t1');
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailScreen), findsNothing);
    expect(locationOf(router), AppRoute.login);
  });

  testWidgets('가입 중 약관 전문은 로그인 없이도 열린다', (tester) async {
    final (container, router) = await boot(tester);
    container.read(sessionProvider.notifier).signOut();
    await tester.pumpAndSettle();

    // 가입 하위 경로까지 로그인 없이 머물 수 있어야 한다. 목록으로 적어 두면
    // 새 하위 화면을 만들 때 빠뜨려 가입 도중 튕긴다.
    router.go(AppRoute.term(Term.service));
    await tester.pumpAndSettle();

    expect(locationOf(router), '/signup/terms/service');
  });
}
