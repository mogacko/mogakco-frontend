import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/signup/domain/term.dart';
import 'package:mogacko/features/signup/presentation/term_detail_screen.dart';
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
    testWidgets('네 항목 모두 라벨에 필수·선택이 표시된다', (tester) async {
      await tester.pumpScreen(const TermsScreen());

      expect(find.text('[필수] 서비스 이용약관'), findsOneWidget);
      expect(find.text('[필수] 개인정보 수집·이용 동의'), findsOneWidget);
      expect(find.text('[필수] 만 14세 이상 확인'), findsOneWidget);
      expect(find.text('[선택] 모임 소식·마케팅 정보 수신'), findsOneWidget);
    });

    testWidgets('화살표를 누르면 약관 전문이 열린다', (tester) async {
      await tester.pumpScreen(const TermsScreen());

      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pumpAndSettle();

      expect(find.byType(TermDetailScreen), findsOneWidget);
      expect(find.text('제1조 (목적)'), findsNothing); // 본문은 통짜 Text 하나다
      expect(find.textContaining('제1조 (목적)'), findsOneWidget);
    });

    testWidgets('전문을 열어도 동의 상태는 바뀌지 않는다', (tester) async {
      await tester.pumpScreen(const TermsScreen());

      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 읽기만 했으므로 여전히 잠겨 있어야 한다.
      expect(isButtonEnabled(tester), isFalse);
    });

    testWidgets('선택 약관 전문은 선택 배지를 단다', (tester) async {
      await tester.pumpScreen(const TermsScreen());

      await tester.tap(find.byIcon(Icons.chevron_right).last);
      await tester.pumpAndSettle();

      expect(find.text('선택 동의'), findsOneWidget);
    });
  });

  group('Term', () {
    test('필수 항목은 세 개다', () {
      expect(Term.values.where((t) => t.required).length, 3);
      expect(Term.marketing.required, isFalse);
    });

    test('모든 약관이 전문을 가진다', () {
      for (final term in Term.values) {
        expect(term.body.trim(), isNotEmpty, reason: term.name);
        expect(term.body.trim().length, greaterThan(100), reason: term.name);
      }
    });
  });
}
