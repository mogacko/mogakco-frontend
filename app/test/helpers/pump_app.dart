import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mogacko/core/router/app_router.dart';
import 'package:mogacko/core/theme/app_theme.dart';
import 'package:mogacko/features/auth/presentation/session_provider.dart';
import 'package:mogacko/shared/data/mock_delay.dart';
import 'package:mogacko/shared/domain/chapter.dart';
import 'package:mogacko/shared/providers/now_provider.dart';

extension PumpApp on WidgetTester {
  /// 화면 하나를 앱 테마와 라우터 컨텍스트 안에서 띄운다.
  ///
  /// 화면들이 `context.push`를 쓰기 때문에 GoRouter가 조상에 있어야 한다.
  /// 전역 라우터를 그대로 쓰면 테스트끼리 이동 이력이 섞여서 매번 새로 만든다.
  /// [animations]를 켜면 반복 애니메이션이 살아난다. 그 경우 pumpAndSettle 이
  /// 끝나지 않으므로 pump 로 시간을 직접 흘려보내야 한다.
  /// [chapter] 로 로그인한 상태에서 띄운다.
  ///
  /// 이 화면들은 로그인해야 닿는 자리다. 세션 없이 띄우면 지역이 정해지지 않아
  /// 어느 지부의 목업을 보는지가 흐려진다. 목업이 가장 두툼한 부산을 기본으로
  /// 둔다 — 지역별 걸러내기를 확인하려면 서울 것과 견줘야 해서다.
  ///
  /// [settle] 이 켜져 있으면 첫 목록이 도착할 때까지 시계를 돌린다.
  ///
  /// 목록 화면은 처음에 스켈레톤부터 그린다. 대부분의 시험은 다 받아온
  /// 뒤를 보고 싶어 하므로 기본으로 넘겨준다. 받는 중을 보려면 끄면 된다.
  ///
  /// pumpAndSettle 만으로는 부족하다. 왕복은 프레임이 아니라 타이머라
  /// 그릴 것이 없으면 시계를 안 돌리고 그대로 돌아온다.
  ///
  /// [now] 를 넘기면 그 시각을 기준으로 그린다. 골든처럼 화면을 통째로 견주는
  /// 자리에서 쓴다. 안 넘기면 실제 지금이라, '8/6 (목)' 같은 날짜 글자가
  /// 하루만 지나도 달라져 어제 만든 골든이 오늘 깨진다.
  Future<ProviderContainer> pumpScreen(
    Widget screen, {
    Brightness brightness = Brightness.light,
    bool animations = false,
    Chapter chapter = Chapter.busan,
    DateTime? now,
    bool? settle,
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
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('home-landed')),
        ),
        // 상세는 앱과 같은 목록을 쓴다. 여기 따로 적으면 새 상세를 만들 때
        // 한쪽만 고쳐 두고 테스트에서만 길이 없어진다.
        ...detailRoutes,
      ],
    );

    // 위젯을 세우기 전에 로그인시킨다. 나중에 바꾸면 첫 프레임이 다른 지역으로
    // 그려졌다가 갈아엎힌다.
    final container = ProviderContainer(
      overrides: [if (now != null) nowProvider.overrideWithValue(now)],
    );
    container.read(sessionProvider.notifier).signIn(chapter: chapter);
    addTearDown(container.dispose);

    await pumpWidget(
      // 홈 화면들이 Riverpod을 쓰므로 항상 감싸 둔다.
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: brightness == Brightness.dark
              ? AppTheme.dark()
              : AppTheme.light(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: !animations),
            child: child!,
          ),
        ),
      ),
    );

    if (settle ?? true) await settleLoad();

    return container;
  }

  /// 목록이 받아올 때까지 시계를 돌린다.
  ///
  /// 필터를 바꾸거나 새로고침하면 새 요청이 뜬다. 그냥 두고 시험을 끝내면
  /// '타이머가 남은 채로 위젯 트리가 사라졌다'로 잡힌다.
  Future<void> settleLoad() async {
    await pump(mockNetworkDelay);
    await pumpAndSettle();
  }
}
