import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/auth/presentation/login_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('카카오와 구글 버튼을 노출한다', (tester) async {
      await tester.pumpScreen(const LoginScreen());

      expect(find.text('카카오로 시작하기'), findsOneWidget);
      expect(find.text('Google로 시작하기'), findsOneWidget);
    });

    /// 플랫폼을 바꿔 띄운다.
    ///
    /// 되돌리기를 addTearDown 으로 걸면 늦다. 테스트 본문이 끝나자마자 검사가
    /// 돌면서 '디버그 변수가 바뀐 채로 남았다'고 잡는다.
    Future<void> pumpOn(WidgetTester tester, TargetPlatform platform) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await tester.pumpScreen(const LoginScreen());
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }

    testWidgets('애플은 iOS 에서만 선다', (tester) async {
      await pumpOn(tester, TargetPlatform.iOS);

      // 다른 소셜 로그인을 두고 애플만 빼면 앱스토어 심사에서 걸린다.
      expect(find.text('Apple로 시작하기'), findsOneWidget);
    });

    testWidgets('안드로이드에는 애플을 두지 않는다', (tester) async {
      await pumpOn(tester, TargetPlatform.android);

      // 애플은 안드로이드 SDK 가 없어 웹 플로를 써야 하고, 그 돌아올 주소를
      // 서버가 열어야 한다. 카카오·구글로 충분해서 그 품을 들이지 않는다.
      expect(find.text('Apple로 시작하기'), findsNothing);
      expect(find.text('카카오로 시작하기'), findsOneWidget);
      expect(find.text('Google로 시작하기'), findsOneWidget);
    });

    testWidgets('약관 안내 문구를 보여준다', (tester) async {
      await tester.pumpScreen(const LoginScreen());

      expect(find.textContaining('이용약관', findRichText: true), findsOneWidget);
    });

    testWidgets('다크 모드에서도 오버플로 없이 그려진다', (tester) async {
      await tester.pumpScreen(const LoginScreen(), brightness: Brightness.dark);

      expect(tester.takeException(), isNull);
      expect(find.text('카카오로 시작하기'), findsOneWidget);
    });

    testWidgets('작은 화면에서도 렌더링이 깨지지 않는다', (tester) async {
      // 세로가 짧은 기기에서 Spacer가 음수 공간을 만들지 않는지 확인한다.
      tester.view
        ..physicalSize = const Size(360, 560)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpScreen(const LoginScreen());

      expect(tester.takeException(), isNull);
    });
  });
}
