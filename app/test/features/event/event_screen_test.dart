import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/event/domain/event.dart';
import 'package:mogacko/features/event/presentation/event_screen.dart';
import 'package:mogacko/shared/widgets/filter_bar.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('EventScreen', () {
    Finder filterPill(String label) => find.descendant(
      of: find.byType(FilterBar<EventKind?>),
      matching: find.text(label),
    );

    testWidgets('지금 보고 있는 지역의 행사만 세운다', (tester) async {
      await tester.pumpScreen(const EventScreen());
      await tester.pumpAndSettle();

      expect(find.text('행사'), findsOneWidget);
      expect(find.textContaining('광안리 야간 산책'), findsOneWidget);
      // 서울 행사는 여기 섞이지 않는다.
      expect(find.textContaining('실전 이력서 클리닉'), findsNothing);
    });

    testWidgets('종류를 고르면 그 종류만 남는다', (tester) async {
      await tester.pumpScreen(const EventScreen());
      await tester.pumpAndSettle();

      await tester.tap(filterPill('해커톤'));
      await tester.pumpAndSettle();

      expect(find.textContaining('여름 해커톤'), findsOneWidget);
      expect(find.textContaining('광안리 야간 산책'), findsNothing);
    });

    testWidgets('이미 신청한 행사는 다시 재촉하지 않는다', (tester) async {
      await tester.pumpScreen(const EventScreen());
      await tester.pumpAndSettle();

      // 목업에서 미리 신청해 둔 행사가 하나 있다.
      expect(find.text('신청 완료'), findsOneWidget);
    });

    testWidgets('신청 전에 언제 어디서 얼마인지 다시 보여준다', (tester) async {
      await tester.pumpScreen(const EventScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('신청하기').first);
      await tester.pumpAndSettle();

      expect(find.text('이 행사에 신청할까요?'), findsOneWidget);
      expect(find.text('참가비'), findsOneWidget);
      expect(find.text('신청 마감'), findsOneWidget);
    });

    testWidgets('확인하면 신청 완료로 바뀐다', (tester) async {
      await tester.pumpScreen(const EventScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('신청하기').first);
      await tester.pumpAndSettle();

      // 카드의 신청 버튼과 시트의 확인 버튼이 같은 글자다.
      // 시트 쪽만 짚어야 눌린 것이 확인 버튼임이 분명해진다.
      await tester.tap(find.widgetWithText(FilledButton, '신청하기'));
      await tester.pumpAndSettle();

      expect(find.text('신청 완료'), findsNWidgets(2));
    });
  });
}
