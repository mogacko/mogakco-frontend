import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/splash/presentation/splash_screen.dart';
import 'package:mogacko/shared/widgets/mogacko_logo.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('로고를 정중앙에 보여준다', (tester) async {
      await tester.pumpScreen(const SplashScreen());
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byType(MogackoLogo), findsOneWidget);

      // 화면 정중앙에 놓였는지 좌표로 확인한다.
      final screen = tester.getRect(find.byType(Scaffold));
      final logo = tester.getRect(find.byType(MogackoLogo));
      expect(logo.center.dx, moreOrLessEquals(screen.center.dx, epsilon: 1));
      expect(logo.center.dy, moreOrLessEquals(screen.center.dy, epsilon: 1));

      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('최소 2초 동안은 로고를 유지한다', (tester) async {
      await tester.pumpScreen(const SplashScreen());

      // 준비 작업이 즉시 끝나더라도 2초 전에는 넘어가면 안 된다.
      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.byType(MogackoLogo), findsOneWidget);
      expect(find.text('login-landed'), findsNothing);

      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('준비가 끝나면 로그인으로 넘어간다', (tester) async {
      await tester.pumpScreen(const SplashScreen());

      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('login-landed'), findsOneWidget);
    });

    testWidgets('이동 전에 화면이 사라져도 예외가 나지 않는다', (tester) async {
      await tester.pumpScreen(const SplashScreen());
      await tester.pump(const Duration(milliseconds: 300));

      // 대기 도중 위젯을 걷어낸다. mounted 확인이 빠지면 여기서 터진다.
      await tester.pumpScreen(const SplashScreen());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(tester.takeException(), isNull);
    });
  });
}
