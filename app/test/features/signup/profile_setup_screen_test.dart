import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/signup/presentation/profile_setup_screen.dart';
import 'package:mogacko/shared/widgets/tag_input_field.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ProfileSetupScreen', () {
    // Finder는 매칭 시점에 평가되므로 미리 만들어 재사용해도 된다.
    final nicknameField = find.byType(TextField).first;

    /// 필수 항목(닉네임·분야)을 채운다.
    Future<void> fillRequired(
      WidgetTester tester, {
      String nickname = 'evan',
    }) async {
      await tester.enterText(nicknameField, nickname);
      await tester.pumpAndSettle();

      final input = find.descendant(
        of: find.byKey(const Key('field-input')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      await tester.enterText(input, '백엔드');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    bool isButtonEnabled(WidgetTester tester) {
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      return button.onPressed != null;
    }

    testWidgets('닉네임 입력 전에는 가입 완료가 잠겨 있다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      expect(isButtonEnabled(tester), isFalse);
    });

    testWidgets('입력을 시작하기 전에는 오류를 띄우지 않는다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      expect(find.text('2자 이상 입력해 주세요'), findsNothing);
    });

    testWidgets('한 글자만 넣으면 길이 안내를 띄우고 버튼을 잠근다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      await tester.enterText(nicknameField, '가');
      await tester.pumpAndSettle();

      expect(find.text('2자 이상 입력해 주세요'), findsOneWidget);
      expect(isButtonEnabled(tester), isFalse);
    });

    testWidgets('허용하지 않는 문자는 사유를 알려준다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      await tester.enterText(nicknameField, '모각코!!');
      await tester.pumpAndSettle();

      expect(find.text('한글, 영문, 숫자, 밑줄만 사용할 수 있어요'), findsOneWidget);
      expect(isButtonEnabled(tester), isFalse);
    });

    testWidgets('닉네임만으로는 가입 완료가 열리지 않는다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      await tester.enterText(nicknameField, '부산개발자');
      await tester.pumpAndSettle();

      expect(isButtonEnabled(tester), isFalse);
    });

    testWidgets('닉네임과 분야를 채우면 가입 완료가 열린다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      await fillRequired(tester, nickname: '부산개발자');

      expect(isButtonEnabled(tester), isTrue);
    });

    testWidgets('앞뒤 공백은 길이 검사에서 제외한다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      await tester.enterText(nicknameField, '  가  ');
      await tester.pumpAndSettle();

      expect(isButtonEnabled(tester), isFalse);
    });

    testWidgets('자기소개는 비어 있어도 가입을 막지 않는다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      await fillRequired(tester);

      expect(isButtonEnabled(tester), isTrue);
    });
    testWidgets('자기소개·소속 입력란을 제공한다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      expect(find.text('자기소개'), findsOneWidget);
      expect(find.text('소속'), findsOneWidget);
    });

    testWidgets('분야·스택·관심분야가 모두 입력형이다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      // 분야·스택·관심분야 모두 입력형이다.
      expect(find.byType(TagInputField), findsNWidgets(3));
      for (final key in ['field-input', 'stack-input', 'interest-input']) {
        expect(find.byKey(Key(key)), findsOneWidget);
      }
    });

    testWidgets('입력하면 겹치는 추천이 뜬다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      final input = find.descendant(
        of: find.byKey(const Key('stack-input')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      await tester.enterText(input, 'sp');
      await tester.pumpAndSettle();

      expect(find.text('Spring'), findsOneWidget);
    });

    testWidgets('추천을 누르면 태그로 담긴다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      final key = find.byKey(const Key('stack-input'));
      final input = find.descendant(of: key, matching: find.byType(TextField));
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      await tester.enterText(input, 'sp');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spring'));
      await tester.pumpAndSettle();

      expect(tester.widget<TagInputField>(key).selected, contains('Spring'));
    });

    testWidgets('목록에 없는 값도 직접 추가할 수 있다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      final key = find.byKey(const Key('stack-input'));
      final input = find.descendant(of: key, matching: find.byType(TextField));
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      await tester.enterText(input, 'Svelte');
      await tester.pumpAndSettle();

      // 목록에 없으면 새로 만드는 칩이 뜬다.
      expect(find.text('+ "Svelte" 추가'), findsOneWidget);
      await tester.tap(find.text('+ "Svelte" 추가'));
      await tester.pumpAndSettle();

      expect(tester.widget<TagInputField>(key).selected, contains('Svelte'));
    });

    testWidgets('대소문자만 다르면 목록 표기로 저장한다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      final key = find.byKey(const Key('stack-input'));
      final input = find.descendant(of: key, matching: find.byType(TextField));
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();

      // 'java'로 쳐도 목록의 'Java'로 정규화돼야 표기가 갈리지 않는다.
      await tester.enterText(input, 'java');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final selected = tester.widget<TagInputField>(key).selected;
      expect(selected, contains('Java'));
      expect(selected, isNot(contains('java')));
    });

    testWidgets('같은 태그를 두 번 담지 않는다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      final key = find.byKey(const Key('stack-input'));
      final input = find.descendant(of: key, matching: find.byType(TextField));
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();

      for (final text in ['Java', 'java']) {
        await tester.enterText(input, text);
        await tester.pumpAndSettle();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      expect(tester.widget<TagInputField>(key).selected, hasLength(1));
    });

    testWidgets('담은 태그를 지울 수 있다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      final key = find.byKey(const Key('stack-input'));
      final input = find.descendant(of: key, matching: find.byType(TextField));
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      await tester.enterText(input, 'Java');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final remove = find.descendant(
        of: key,
        matching: find.byIcon(Icons.close),
      );
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();

      expect(tester.widget<TagInputField>(key).selected, isEmpty);
    });

    testWidgets('분야는 하나만 담기고 상한에 닿으면 입력이 잠긴다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());
      await fillRequired(tester);

      final key = find.byKey(const Key('field-input'));
      expect(tester.widget<TagInputField>(key).selected, ['백엔드']);

      final input = find.descendant(of: key, matching: find.byType(TextField));
      expect(tester.widget<TextField>(input).enabled, isFalse);
    });

    testWidgets('분야는 목록에 없는 값도 적을 수 있다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());

      final key = find.byKey(const Key('field-input'));
      final input = find.descendant(of: key, matching: find.byType(TextField));
      await tester.ensureVisible(input);
      await tester.pumpAndSettle();
      await tester.enterText(input, '사진');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(tester.widget<TagInputField>(key).selected, ['사진']);
      expect(isButtonEnabled(tester), isFalse); // 닉네임이 아직 비어 있다
    });

    testWidgets('분야를 지우면 가입 완료가 다시 잠긴다', (tester) async {
      await tester.pumpScreen(const ProfileSetupScreen());
      await fillRequired(tester);
      expect(isButtonEnabled(tester), isTrue);

      final remove = find.descendant(
        of: find.byKey(const Key('field-input')),
        matching: find.byIcon(Icons.close),
      );
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();

      expect(isButtonEnabled(tester), isFalse);
    });
  });
}
