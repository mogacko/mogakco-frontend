import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
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
}

final appRouter = GoRouter(
  initialLocation: AppRoute.splash,
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
    // 홈은 다음 스프린트 범위. 가입 흐름의 종착지만 잡아둔다.
    GoRoute(path: AppRoute.home, builder: (_, _) => const _HomePlaceholder()),
  ],
);

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

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: const Center(child: Text('다음 스프린트 범위')),
    );
  }
}
