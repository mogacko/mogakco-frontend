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

    testWidgets('셋을 나란히 세운다', (tester) async {
      await tester.pumpScreen(const LoginScreen());

      // iOS 를 네이티브로 돌릴 때 다른 소셜 로그인을 두고 애플만 빼면
      // 앱스토어 심사에서 걸린다.
      expect(find.text('Apple로 시작하기'), findsOneWidget);
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
