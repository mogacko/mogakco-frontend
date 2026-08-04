import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/session_provider.dart';
import '../../features/community/domain/post.dart';
import '../../features/community/presentation/post_detail_screen.dart';
import '../../features/community/presentation/post_write_screen.dart';
import '../../features/event/presentation/event_create_screen.dart';
import '../../features/event/presentation/my_events_screen.dart';
import '../../features/member/presentation/member_screen.dart';
import '../../features/safety/presentation/blocked_members_screen.dart';
import '../../features/notification/presentation/notification_screen.dart';
import '../../features/notification/presentation/notification_settings_screen.dart';
import '../../features/profile/presentation/profile_edit_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/community/presentation/search_screen.dart';
import '../../features/event/presentation/event_detail_screen.dart';
import '../../features/meetup/presentation/meetup_create_screen.dart';
import '../../features/meetup/presentation/meetup_detail_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/signup/domain/term.dart';
import '../../features/signup/presentation/term_detail_screen.dart';
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
  static const notifications = '/notifications';
  static const notificationSettings = '/settings/notifications';
  static const blockedMembers = '/settings/blocked';
  static const settings = '/settings';
  static const profileEdit = '/profile/edit';
  static const search = '/search';

  /// 남의 프로필. 목업에서는 닉네임이 곧 id 다.
  static String member(String id) => '/user/$id';

  /// 하나를 열어 보는 자리.
  ///
  /// Navigator 로만 올리면 주소가 바뀌지 않는다. 네이티브는 그래도 되지만
  /// 웹과 PWA 는 뒤로가기가 주소를 기준으로 움직여서, 상세를 건너뛰고 그
  /// 이전 주소로 가버린다. iOS 를 PWA 로 쓰는 동안은 그게 곧 실사용이다.
  ///
  /// 라우트로 두면 한 코드로 둘 다 맞는다 — context.push 가 스택과 주소를
  /// 함께 민다.
  static String post(String id) => '/post/$id';

  /// 어느 게시판에 쓰는지를 주소에 담는다. 새로고침해도 고른 게시판이 남고,
  /// 뒤로 갔다 와도 자유로 되돌아가지 않는다.
  static String postWrite(PostBoard board) => '/post/new/${board.name}';
  static String meetup(String id) => '/meetup/$id';
  static const meetupCreate = '/meetup/new';
  static String event(String id) => '/event/$id';
  static const eventCreate = '/event/new';
  static const myEvents = '/event/mine';
  static String term(Term value) => '/signup/terms/${value.name}';

  /// 로그인하지 않은 사람만 머무는 자리.
  ///
  /// 로그인한 채로 여기 들어오면 홈으로 되돌린다. 브라우저 뒤로가기로 가입
  /// 화면에 돌아가는 것도 이 규칙이 막는다 — 라우트 스택은 비었는데 브라우저
  /// 히스토리에는 항목이 남아 있어서 생기는 일이다.
  ///
  /// 가입은 하위 경로(약관 전문)까지 포함해야 한다. 목록으로 적어 두면 새
  /// 하위 화면을 만들 때마다 여기를 같이 고쳐야 하고, 빠뜨리면 가입 도중
  /// 로그인 화면으로 튕긴다.
  static bool isSignedOutOnly(String location) =>
      location == splash ||
      location == login ||
      location.startsWith('/signup');
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
      ...detailRoutes,
    ],
  );
});

/// 하나를 열어 보는 화면들.
///
/// 테스트 하네스도 같은 목록을 쓴다. 두 곳에 따로 적으면 새 상세를 만들 때
/// 한쪽만 고쳐 두고 테스트에서만 길이 없어진다.
final detailRoutes = <RouteBase>[
  GoRoute(
    path: AppRoute.notifications,
    builder: (_, _) => const NotificationScreen(),
  ),
  // '/settings/notifications' 가 먼저 와야 한다. go_router 는 먼저 맞는 것을
  // 쓰므로 '/settings' 를 앞에 두면 하위 경로가 가려진다.
  GoRoute(
    path: AppRoute.notificationSettings,
    builder: (_, _) => const NotificationSettingsScreen(),
  ),
  GoRoute(
    path: AppRoute.blockedMembers,
    builder: (_, _) => const BlockedMembersScreen(),
  ),
  GoRoute(path: AppRoute.settings, builder: (_, _) => const SettingsScreen()),
  GoRoute(
    path: AppRoute.profileEdit,
    builder: (_, _) => const ProfileEditScreen(),
  ),
  GoRoute(path: AppRoute.search, builder: (_, _) => const SearchScreen()),
  GoRoute(
    path: '/user/:id',
    builder: (_, state) => MemberScreen(memberId: state.pathParameters['id']!),
  ),
  // '/post/new/...' 가 먼저 와야 한다. 뒤에 두면 :id 가 먼저 물어 'new' 라는
  // id 를 가진 글을 찾다가 '찾을 수 없어요' 가 뜬다.
  GoRoute(
    path: '/post/new/:board',
    builder: (_, state) => PostWriteScreen(
      board: PostBoard.values.byName(state.pathParameters['board']!),
    ),
  ),
  GoRoute(
    path: '/post/:id',
    builder: (_, state) =>
        PostDetailScreen(postId: state.pathParameters['id']!),
  ),
  // '/meetup/new' 가 먼저 와야 한다. 뒤에 두면 :id 가 먼저 물어서 'new' 라는
  // id 를 가진 모임을 찾다가 '찾을 수 없어요' 가 뜬다.
  GoRoute(
    path: AppRoute.meetupCreate,
    builder: (_, _) => const MeetupCreateScreen(),
  ),
  GoRoute(
    path: '/meetup/:id',
    builder: (_, state) =>
        MeetupDetailScreen(meetupId: state.pathParameters['id']!),
  ),
  // '/event/new' 와 '/event/mine' 이 먼저 와야 한다. 뒤에 두면 :id 가 먼저
  // 물어 'new' 라는 id 를 가진 행사를 찾다가 '찾을 수 없어요'가 뜬다.
  GoRoute(
    path: AppRoute.eventCreate,
    builder: (_, _) => const EventCreateScreen(),
  ),
  GoRoute(path: AppRoute.myEvents, builder: (_, _) => const MyEventsScreen()),
  GoRoute(
    path: '/event/:id',
    builder: (_, state) =>
        EventDetailScreen(eventId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/signup/terms/:term',
    builder: (_, state) => TermDetailScreen(
      term: Term.values.byName(state.pathParameters['term']!),
    ),
  ),
];

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
