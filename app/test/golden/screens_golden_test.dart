import 'dart:io';

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

import '../helpers/pump_app.dart';

/// 화면 렌더링을 이미지로 남긴다.
///
/// 골든 이미지는 렌더 엔진 버전에 따라 미세하게 달라질 수 있어 CI 게이트로 쓰기보다
/// 디자인 확인·리뷰용으로 둔다. 갱신은 `flutter test --update-goldens`.
void main() {
  // iPhone 13 / 일반적인 안드로이드 세로 화면에 가까운 크기
  const viewport = Size(390, 844);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadPretendard();
    await _loadIconFonts();
  });

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

    await tester.pumpScreen(screen, brightness: brightness);
    // 진입 애니메이션을 끝까지 돌려 최종 상태를 담는다.
    await tester.pump(const Duration(milliseconds: 1200));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/$name.png'),
    );
  }

  group('라이트 모드', () {
    testWidgets('홈', (tester) async {
      await expectGolden(tester, const AppShell(), 'home_light');
    });

    testWidgets('홈 지역 메뉴', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpScreen(const AppShell());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
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
