import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
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
    GoRoute(path: AppRoute.home, builder: (_, _) => const AppShell()),
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
