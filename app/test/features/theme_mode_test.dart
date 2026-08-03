import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/app.dart';
import 'package:mogacko/core/theme/app_colors.dart';
import 'package:mogacko/core/theme/app_theme.dart';
import 'package:mogacko/features/profile/presentation/settings_screen.dart';
import 'package:mogacko/shared/providers/theme_mode_provider.dart';

import '../helpers/pump_app.dart';

void main() {
  group('화면 모드', () {
    testWidgets('지금 무엇으로 보고 있는지 줄에 적는다', (tester) async {
      await tester.pumpScreen(const SettingsScreen());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('화면 모드'));
      await tester.pumpAndSettle();

      // 기본은 기기 설정을 따른다.
      expect(find.text('시스템 설정'), findsOneWidget);
    });

    testWidgets('골라서 바꾸면 줄에 바로 반영된다', (tester) async {
      await tester.pumpScreen(const SettingsScreen());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('화면 모드'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('화면 모드'));
      await tester.pumpAndSettle();

      // 시트에는 지금 고른 것과 나머지가 함께 뜬다.
      expect(find.text('항상 밝게'), findsOneWidget);
      await tester.tap(find.text('라이트'));
      await tester.pumpAndSettle();

      expect(find.text('라이트'), findsOneWidget);
      expect(find.text('시스템 설정'), findsNothing);
    });

    testWidgets('물러나면 바뀌지 않는다', (tester) async {
      await tester.pumpScreen(const SettingsScreen());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('화면 모드'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('화면 모드'));
      await tester.pumpAndSettle();

      // 시트 바깥을 눌러 닫는다.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('시스템 설정'), findsOneWidget);
    });

    testWidgets('고른 값이 실제 테마에 걸린다', (tester) async {
      // 화면 하나가 아니라 앱을 통째로 띄워야 themeMode 가 실제로 쓰인다.
      await tester.pumpWidget(const ProviderScope(child: MogackoApp()));
      // 스플래시가 로그인으로 넘어가는 타이머를 흘려보낸다. 남겨 두면
      // 위젯 트리가 사라진 뒤에도 타이머가 살아 있어 테스트가 끝나지 못한다.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MogackoApp)),
      );
      container.read(themeModeProvider.notifier).select(ThemeMode.dark);
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });

    test('두 테마가 같은 토큰을 빠짐없이 채운다', () {
      // 한쪽에만 값을 넣고 다른 쪽을 빠뜨리면 그 화면에서만 색이 어긋난다.
      final light = AppTheme.light().extension<AppColors>()!;
      final dark = AppTheme.dark().extension<AppColors>()!;

      // 라이트의 카드 테두리만 투명하다. 그게 의도다.
      expect(light.cardBorder.a, 0);
      expect(dark.cardBorder.a, 1);
      expect(light.background, isNot(dark.background));
    });
  });
}
