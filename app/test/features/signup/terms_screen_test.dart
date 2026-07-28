import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/signup/presentation/terms_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('TermsScreen', () {
    /// 전체 동의 타일 + 개별 항목 4개 = 체크박스 5개
    Finder checkboxAt(int index) => find.byType(Checkbox).at(index);

    bool isButtonEnabled(WidgetTester tester) {
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      return button.onPressed != null;
    }

    testWidgets('필수 약관 전에는 계속하기가 잠겨 있다', (tester) async {
      await tester.pumpScreen(const TermsScreen());

      expect(isButtonEnabled(tester), isFalse);
    });

    testWidgets('전체 동의를 누르면 모든 항목이 켜지고 버튼이 열린다', (tester) async {
      await tester.pumpScreen(const TermsScreen());

      await tester.tap(find.text('전체 동의'));
      await tester.pumpAndSettle();

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(checkboxes.every((c) => c.value == true), isTrue);
      expect(isButtonEnabled(tester), isTrue);
    });

    testWidgets('선택 항목만 빠져도 계속하기는 열려 있다', (tester) async {
      await tester.pumpScreen(const TermsScreen());

      await tester.tap(find.text('전체 동의'));
      await tester.pumpAndSettle();

      // 마지막 체크박스가 선택 항목(마케팅 수신)이다.
      await tester.tap(checkboxAt(4));
      await tester.pumpAndSettle();

      expect(isButtonEnabled(tester), isTrue);
    });

    testWidgets('필수 항목이 하나라도 빠지면 계속하기가 다시 잠긴다', (tester) async {
      await tester.pumpScreen(const TermsScreen());

      await tester.tap(find.text('전체 동의'));
      await tester.pumpAndSettle();

      // 인덱스 1은 첫 번째 필수 항목(서비스 이용약관)이다.
      await tester.tap(checkboxAt(1));
      await tester.pumpAndSettle();

      expect(isButtonEnabled(tester), isFalse);
    });

    testWidgets('개별 항목을 모두 켜면 전체 동의도 함께 켜진다', (tester) async {
      await tester.pumpScreen(const TermsScreen());

      for (var i = 1; i <= 4; i++) {
        await tester.tap(checkboxAt(i));
        await tester.pumpAndSettle();
      }

      final agreeAll = tester.widget<Checkbox>(checkboxAt(0));
      expect(agreeAll.value, isTrue);
    });
  });
}
