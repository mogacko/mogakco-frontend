import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/auth/presentation/login_screen.dart';
import 'package:mogacko/features/shell/presentation/app_shell.dart';
import 'package:mogacko/features/signup/presentation/chapter_select_screen.dart';
import 'package:mogacko/features/signup/presentation/profile_setup_screen.dart';
import 'package:mogacko/features/signup/presentation/signup_complete_screen.dart';
import 'package:mogacko/features/signup/domain/term.dart';
import 'package:mogacko/features/signup/presentation/term_detail_screen.dart';
import 'package:mogacko/features/signup/presentation/terms_screen.dart';
import 'package:mogacko/features/splash/presentation/splash_screen.dart';
import 'package:mogacko/shared/data/mock_delay.dart';
import 'package:mogacko/features/community/domain/post.dart';
import 'package:mogacko/features/community/presentation/post_detail_screen.dart';
import 'package:mogacko/features/community/presentation/post_write_screen.dart';
import 'package:mogacko/features/event/presentation/event_create_screen.dart';
import 'package:mogacko/features/member/presentation/member_screen.dart';
import 'package:mogacko/features/safety/presentation/blocked_members_screen.dart';
import 'package:mogacko/features/notification/presentation/notification_screen.dart';
import 'package:mogacko/features/notification/presentation/notification_settings_screen.dart';
import 'package:mogacko/features/community/presentation/search_screen.dart';
import 'package:mogacko/features/profile/presentation/profile_edit_screen.dart';
import 'package:mogacko/features/profile/presentation/settings_screen.dart';
import 'package:mogacko/features/event/presentation/event_detail_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_create_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_detail_screen.dart';
import 'package:mogacko/shared/widgets/app_bottom_nav.dart';

import '../helpers/fake_image_http.dart';
import '../helpers/pump_app.dart';

/// 화면 렌더링을 이미지로 남긴다.
///
/// 골든 이미지는 렌더 엔진 버전에 따라 미세하게 달라질 수 있어 CI 게이트로 쓰기보다
/// 디자인 확인·리뷰용으로 둔다. 갱신은 `flutter test --update-goldens`.
/// 골든이 보는 '지금'.
///
/// 실제 지금으로 두면 '8/6 (목)' 같은 날짜 글자가 하루만 지나도 달라져서,
/// 어제 만든 골든이 오늘 아침에 깨진다. 그러면 진짜 회귀와 날짜 흐름을
/// 가릴 수 없게 되고 결국 골든을 안 믿게 된다.
///
/// 목요일로 잡았다. 주중이라 '오늘·내일'과 주말 모임이 함께 보인다.
final _now = DateTime(2026, 3, 5, 10, 30);

void main() {
  // iPhone 13 / 일반적인 안드로이드 세로 화면에 가까운 크기
  const viewport = Size(390, 844);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // 바인딩이 자기 HttpClient 를 건 다음이라야 이쪽이 이긴다.
    installFakeImageHttpClient();
    await _loadPretendard();
    await _loadIconFonts();
  });

  /// 화면 안의 이미지를 실제로 받아 그릴 때까지 기다린다.
  ///
  /// 위젯 테스트는 가짜 시간 위에서 돌아 이미지 디코드가 끝나지 않는다.
  /// 그냥 찍으면 포스터 자리에 늘 대체 표시만 남는다. [WidgetTester.runAsync]
  /// 안에서만 진짜 비동기가 돌아간다.
  Future<void> settleImages(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        await precacheImage(image.image, element);
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> expectGolden(
    WidgetTester tester,
    Widget screen,
    String name, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view
      ..physicalSize = viewport
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpScreen(screen, brightness: brightness, now: _now);
    // 진입 애니메이션을 끝까지 돌려 최종 상태를 담는다.
    await tester.pump(const Duration(milliseconds: 1200));

    await settleImages(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/$name.png'),
    );
  }

  /// 탭 하나를 열어 그 상태를 담는다.
  ///
  /// 탭은 셸 안에서 갈리므로 화면만 따로 띄우면 탭 바가 빠져 실제 모습과
  /// 달라진다. 셸을 띄운 뒤 해당 탭을 눌러 들어간다.
  Future<void> expectTabGolden(
    WidgetTester tester,
    AppTab tab,
    String name, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view
      ..physicalSize = viewport
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpScreen(
      const AppShell(),
      brightness: brightness,
      now: _now,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text(tab.label),
      ),
    );
    await tester.pumpAndSettle();

    await settleImages(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/$name.png'),
    );
  }

  /// 검색어를 친 뒤의 검색 화면.
  ///
  /// 빈 채로 담으면 입력칸 한 줄만 남아 볼 것이 없다.
  Future<void> expectSearchGolden(
    WidgetTester tester,
    String name, {
    Brightness brightness = Brightness.light,
  }) async {
    tester.view
      ..physicalSize = viewport
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpScreen(
      const SearchScreen(),
      brightness: brightness,
      now: _now,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '모각코');
    await tester.pumpAndSettle();

    await settleImages(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/$name.png'),
    );
  }

  /// 장소 검색 칸을 실제로 써 본 모습.
  ///
  /// 검색 결과 목록과 고른 뒤의 지도는 폼을 띄우기만 해서는 안 나온다.
  /// 눈으로 볼 곳이 정작 그 두 상태라 여기서 따로 담는다.
  Future<void> expectPlaceGolden(
    WidgetTester tester,
    String name, {
    bool pick = false,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view
      ..physicalSize = viewport
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpScreen(
      const MeetupCreateScreen(),
      brightness: brightness,
      now: _now,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '모모스');
    // 디바운스가 지나야 검색이 나가고, 목업 왕복이 끝나야 결과가 온다.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(mockNetworkDelay);
    await tester.pumpAndSettle();

    if (pick) {
      await tester.tap(find.text('모모스커피 온천장'));
      await tester.pumpAndSettle();
    }

    await settleImages(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/$name.png'),
    );
  }

  group('라이트 모드', () {
    testWidgets('홈', (tester) async {
      await expectGolden(tester, const AppShell(), 'home_light');
    });

    testWidgets('커뮤니티', (tester) async {
      await expectTabGolden(tester, AppTab.community, 'community_light');
    });

    testWidgets('모임', (tester) async {
      await expectTabGolden(tester, AppTab.meetup, 'meetup_light');
    });

    testWidgets('행사', (tester) async {
      await expectTabGolden(tester, AppTab.event, 'event_light');
    });

    testWidgets('내 정보', (tester) async {
      await expectTabGolden(tester, AppTab.profile, 'profile_tab_light');
    });

    testWidgets('글 상세', (tester) async {
      await expectGolden(
        tester,
        const PostDetailScreen(postId: 'busan-t1'),
        'post_detail_light',
      );
    });

    testWidgets('모각코 상세', (tester) async {
      await expectGolden(
        tester,
        const MeetupDetailScreen(meetupId: 'busan-1'),
        'meetup_detail_light',
      );
    });

    testWidgets('행사 상세', (tester) async {
      await expectGolden(
        tester,
        const EventDetailScreen(eventId: 'busan-e1'),
        'event_detail_light',
      );
    });

    testWidgets('모각코 만들기', (tester) async {
      await expectGolden(
        tester,
        const MeetupCreateScreen(),
        'meetup_create_light',
      );
    });

    testWidgets('글쓰기', (tester) async {
      await expectGolden(
        tester,
        const PostWriteScreen(board: PostBoard.talk),
        'post_write_light',
      );
    });

    testWidgets('알림', (tester) async {
      await expectGolden(
        tester,
        const NotificationScreen(),
        'notification_light',
      );
    });

    testWidgets('남의 프로필', (tester) async {
      await expectGolden(
        tester,
        const MemberScreen(memberId: '재현'),
        'member_light',
      );
    });

    testWidgets('설정', (tester) async {
      await expectGolden(tester, const SettingsScreen(), 'settings_light');
    });

    testWidgets('행사 올리기', (tester) async {
      await expectGolden(
        tester,
        const EventCreateScreen(),
        'event_create_light',
      );
    });

    testWidgets('접힌 모각코', (tester) async {
      await expectGolden(
        tester,
        const MeetupDetailScreen(meetupId: 'busan-4'),
        'meetup_cancelled_light',
      );
    });

    testWidgets('차단한 사람', (tester) async {
      await expectGolden(
        tester,
        const BlockedMembersScreen(),
        'blocked_light',
      );
    });

    testWidgets('알림 설정', (tester) async {
      await expectGolden(
        tester,
        const NotificationSettingsScreen(),
        'notification_settings_light',
      );
    });

    testWidgets('프로필 수정', (tester) async {
      await expectGolden(
        tester,
        const ProfileEditScreen(),
        'profile_edit_light',
      );
    });

    testWidgets('글 검색', (tester) async {
      await expectSearchGolden(tester, 'search_light');
    });

    testWidgets('장소 검색 결과', (tester) async {
      await expectPlaceGolden(tester, 'meetup_place_search_light');
    });

    testWidgets('장소 고른 뒤', (tester) async {
      await expectPlaceGolden(
        tester,
        'meetup_place_picked_light',
        pick: true,
      );
    });

    testWidgets('참여 확인 시트', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpScreen(const AppShell(), now: _now);
      await tester.pumpAndSettle();
      await tester.tap(find.text('참여 신청').first);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('images/join_sheet_light.png'),
      );
    });

    testWidgets('홈 지역 메뉴', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpScreen(const AppShell(), now: _now);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('images/home_menu_light.png'),
      );
    });

    testWidgets('스플래시', (tester) async {
      await expectGolden(tester, const SplashScreen(), 'splash_light');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('로그인', (tester) async {
      await expectGolden(tester, const LoginScreen(), 'login_light');
    });

    testWidgets('약관 동의', (tester) async {
      await expectGolden(tester, const TermsScreen(), 'terms_light');
    });

    testWidgets('지역 선택', (tester) async {
      await expectGolden(tester, const ChapterSelectScreen(), 'chapter_light');
    });

    testWidgets('프로필 설정', (tester) async {
      await expectGolden(tester, const ProfileSetupScreen(), 'profile_light');
    });

    testWidgets('약관 전문', (tester) async {
      await expectGolden(
        tester,
        const TermDetailScreen(term: Term.service),
        'term_detail_light',
      );
    });

    testWidgets('가입 완료', (tester) async {
      await expectGolden(
        tester,
        const SignupCompleteScreen(),
        'complete_light',
      );
    });
  });

  group('다크 모드', () {
    testWidgets('홈', (tester) async {
      await expectGolden(
        tester,
        const AppShell(),
        'home_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('커뮤니티', (tester) async {
      await expectTabGolden(
        tester,
        AppTab.community,
        'community_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('모임', (tester) async {
      await expectTabGolden(
        tester,
        AppTab.meetup,
        'meetup_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('행사', (tester) async {
      await expectTabGolden(
        tester,
        AppTab.event,
        'event_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('내 정보', (tester) async {
      await expectTabGolden(
        tester,
        AppTab.profile,
        'profile_tab_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('글 상세', (tester) async {
      await expectGolden(
        tester,
        const PostDetailScreen(postId: 'busan-t1'),
        'post_detail_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('글쓰기', (tester) async {
      await expectGolden(
        tester,
        const PostWriteScreen(board: PostBoard.talk),
        'post_write_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('알림', (tester) async {
      await expectGolden(
        tester,
        const NotificationScreen(),
        'notification_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('설정', (tester) async {
      await expectGolden(
        tester,
        const SettingsScreen(),
        'settings_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('프로필 수정', (tester) async {
      await expectGolden(
        tester,
        const ProfileEditScreen(),
        'profile_edit_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('글 검색', (tester) async {
      await expectSearchGolden(
        tester,
        'search_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('행사 상세', (tester) async {
      await expectGolden(
        tester,
        const EventDetailScreen(eventId: 'busan-e1'),
        'event_detail_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('스플래시', (tester) async {
      await expectGolden(
        tester,
        const SplashScreen(),
        'splash_dark',
        brightness: Brightness.dark,
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('로그인', (tester) async {
      await expectGolden(
        tester,
        const LoginScreen(),
        'login_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('약관 동의', (tester) async {
      await expectGolden(
        tester,
        const TermsScreen(),
        'terms_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('지역 선택', (tester) async {
      await expectGolden(
        tester,
        const ChapterSelectScreen(),
        'chapter_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('프로필 설정', (tester) async {
      await expectGolden(
        tester,
        const ProfileSetupScreen(),
        'profile_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('약관 전문', (tester) async {
      await expectGolden(
        tester,
        const TermDetailScreen(term: Term.service),
        'term_detail_dark',
        brightness: Brightness.dark,
      );
    });

    testWidgets('가입 완료', (tester) async {
      await expectGolden(
        tester,
        const SignupCompleteScreen(),
        'complete_dark',
        brightness: Brightness.dark,
      );
    });
  });
}

/// 아이콘 폰트를 등록한다.
///
/// 등록하지 않으면 골든에서 아이콘이 전부 네모로 찍혀 실제 모습을 볼 수 없다.
/// rootBundle에는 없어서 테스트 에셋 디렉터리에서 직접 읽는다.
Future<void> _loadIconFonts() async {
  // fontPackage가 붙은 아이콘은 'packages/<패키지>/<패밀리>'로 등록해야 잡힌다.
  const fonts = {
    'MaterialIcons': 'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
    'packages/cupertino_icons/CupertinoIcons':
        'build/unit_test_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  };

  for (final entry in fonts.entries) {
    final file = File(entry.value);
    if (!file.existsSync()) continue;
    final bytes = await file.readAsBytes();
    await (FontLoader(
      entry.key,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

/// 테스트 환경은 기본 폰트만 알고 있어서 커스텀 폰트를 직접 등록해야 한다.
/// 등록하지 않으면 골든 이미지의 한글이 전부 네모로 찍힌다.
Future<void> _loadPretendard() async {
  final loader = FontLoader('Pretendard');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Pretendard-$weight.otf'));
  }
  await loader.load();
}
