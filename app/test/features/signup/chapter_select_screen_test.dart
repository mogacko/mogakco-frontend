import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/shared/domain/chapter.dart';
import 'package:mogacko/features/signup/presentation/chapter_select_screen.dart';
import 'package:mogacko/shared/widgets/mogacko_logo.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('Chapter', () {
    test('운영 중인 지역은 서울과 부산뿐이다', () {
      expect(Chapter.open, [Chapter.seoul, Chapter.busan]);
    });

    test('모든 지역이 로고 경로를 가진다', () {
      for (final chapter in Chapter.values) {
        expect(chapter.logoAsset, endsWith('mogakco-${chapter.name}.svg'));
      }
    });
  });

  group('ChapterSelectScreen', () {
    bool isButtonEnabled(WidgetTester tester) {
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      return button.onPressed != null;
    }

    testWidgets('운영 중인 지역만 노출한다', (tester) async {
      await tester.pumpScreen(const ChapterSelectScreen());

      // 열린 지역 수만큼만 워드마크가 그려져야 한다.
      expect(find.byType(MogackoLogo), findsNWidgets(Chapter.open.length));
      expect(find.byType(MogackoLogo), findsNWidgets(2));
    });

    testWidgets('지역을 고르기 전에는 다음이 잠겨 있다', (tester) async {
      await tester.pumpScreen(const ChapterSelectScreen());

      expect(isButtonEnabled(tester), isFalse);
    });

    testWidgets('지역을 고르면 다음이 열린다', (tester) async {
      await tester.pumpScreen(const ChapterSelectScreen());

      await tester.tap(find.byType(MogackoLogo).first);
      await tester.pumpAndSettle();

      expect(isButtonEnabled(tester), isTrue);
    });

    testWidgets('다른 지역을 고르면 선택이 하나만 유지된다', (tester) async {
      await tester.pumpScreen(const ChapterSelectScreen());

      await tester.tap(find.byType(MogackoLogo).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MogackoLogo).last);
      await tester.pumpAndSettle();

      // 체크 아이콘은 항상 한 개만 켜져 있어야 한다.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('확장 예정 안내를 보여준다', (tester) async {
      await tester.pumpScreen(const ChapterSelectScreen());

      expect(find.text('다른 지역도 순차적으로 열립니다'), findsOneWidget);
    });

    testWidgets('다크 모드에서도 오버플로 없이 그려진다', (tester) async {
      await tester.pumpScreen(
        const ChapterSelectScreen(),
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
