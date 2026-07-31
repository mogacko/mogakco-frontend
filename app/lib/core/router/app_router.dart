import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/session_provider.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/signup/presentation/chapter_select_screen.dart';
import '../../features/signup/presentation/profile_setup_screen.dart';
import '../../features/signup/presentation/signup_complete_screen.dart';
import '../../features/signup/presentation/terms_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

abstract final class AppRoute {
  static const splash = '/';
  static const login = '/login';
  static const signupTerms = '/signup/terms';
  static const signupChapter = '/signup/chapter';
  static const signupProfile = '/signup/profile';
  static const signupComplete = '/signup/complete';
  static const home = '/home';

  /// 로그인하지 않은 사람만 머무는 자리.
  ///
  /// 로그인한 채로 여기 들어오면 홈으로 되돌린다. 브라우저 뒤로가기로 가입
  /// 화면에 돌아가는 것도 이 규칙이 막는다 — 라우트 스택은 비었는데 브라우저
  /// 히스토리에는 항목이 남아 있어서 생기는 일이다.
  static const _signedOutOnly = {
    splash,
    login,
    signupTerms,
    signupChapter,
    signupProfile,
    signupComplete,
  };

  static bool isSignedOutOnly(String location) =>
      _signedOutOnly.contains(location);
}

/// 라우터.
///
/// 세션을 봐야 해서 프로바이더로 둔다. 전역 상수로 두면 로그인 상태를 읽을
/// 방법이 없다.
final routerProvider = Provider<GoRouter>((ref) {
  // 세션이 바뀌면 라우터가 redirect 를 다시 판단해야 한다. Riverpod 의 변화를
  // go_router 가 알아들을 수 있는 형태로 넘긴다.
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoute.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      // 파생 프로바이더가 아니라 원본을 읽는다. redirect 안에서 ref.read 로
      // 파생값을 집으면 원본이 이미 바뀐 뒤에도 옛 값이 나온다 — 아무도
      // 그 파생값을 보고 있지 않아 다시 계산될 계기가 없어서다.
      final signedIn = ref.read(sessionProvider) != null;
      final signedOutOnly = AppRoute.isSignedOutOnly(state.matchedLocation);

      // 로그인했는데 가입·로그인 화면에 있으면 홈으로.
      if (signedIn && signedOutOnly) return AppRoute.home;
      // 로그인 안 했는데 홈으로 가려 하면 로그인으로.
      if (!signedIn && !signedOutOnly) return AppRoute.login;
      return null;
    },
    routes: [
      GoRoute(path: AppRoute.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoute.login,
        pageBuilder: (_, state) => _fadeThrough(state, const LoginScreen()),
      ),
      GoRoute(path: AppRoute.signupTerms, builder: (_, _) => const TermsScreen()),
      GoRoute(
        path: AppRoute.signupChapter,
        builder: (_, _) => const ChapterSelectScreen(),
      ),
      GoRoute(
        path: AppRoute.signupProfile,
        builder: (_, _) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoute.signupComplete,
        builder: (_, _) => const SignupCompleteScreen(),
      ),
      GoRoute(path: AppRoute.home, builder: (_, _) => const AppShell()),
    ],
  );
});

/// 스플래시 → 로그인은 밀려나는 느낌 없이 부드럽게 넘긴다.
CustomTransitionPage<void> _fadeThrough(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 450),
    child: child,
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
