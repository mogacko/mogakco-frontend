import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/meetup/presentation/meetup_create_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/shared/widgets/form_field_block.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('모각코 만들기', () {
    /// 정원 숫자. 주간 알약에도 날짜 숫자가 있어 화면 전체에서 찾으면
    /// 오늘이 며칠이냐에 따라 걸리는 게 달라진다.
    Finder capacity(String value) => find.descendant(
      of: find.byType(CountStepper),
      matching: find.text(value),
    );

    /// 오늘부터 이레가 알약으로 놓인다. 세 번째 칸을 누른다.
    Future<void> pickThirdDay(WidgetTester tester) async {
      await tester.tap(find.byType(InkWell).at(3));
      await tester.pumpAndSettle();
    }

    testWidgets('장소·주소·날짜가 다 차야 만들 수 있다', (tester) async {
      await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      final button = find.widgetWithText(FilledButton, '만들기');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, '모모스커피');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(1), '부산 동래구');
      await tester.pumpAndSettle();
      // 날짜가 없으면 아직 열리지 않는다. 언제 모이는지 없는 모임은 없다.
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });

    testWidgets('날짜를 고르면 그 날의 시각과 정원 줄이 생긴다', (tester) async {
      await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      expect(find.text('19:00'), findsNothing);

      await pickThirdDay(tester);

      // 첫 날은 기본값으로 채워진다. 매번 고르게 두지 않는다.
      expect(find.text('19:00'), findsOneWidget);
      expect(capacity('8'), findsOneWidget);
    });

    testWidgets('여러 날을 한 모임으로 묶는다', (tester) async {
      await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).at(4));
      await tester.pumpAndSettle();

      // 두 줄 모두 직전 값을 이어받는다.
      expect(find.text('19:00'), findsNWidgets(2));
    });

    testWidgets('다시 누르면 그 날이 빠진다', (tester) async {
      await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      await pickThirdDay(tester);
      expect(find.text('19:00'), findsOneWidget);

      await pickThirdDay(tester);
      expect(find.text('19:00'), findsNothing);
    });

    testWidgets('만들면 목록에 그 자리가 생기고 내가 참여 중이다', (tester) async {
      final container = await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '카페 테스트');
      await tester.enterText(find.byType(TextField).at(1), '부산광역시 동래구 온천동');
      await tester.pumpAndSettle();
      await pickThirdDay(tester);

      await tester.tap(find.widgetWithText(FilledButton, '만들기'));
      await tester.pumpAndSettle();

      final made = container
          .read(meetupListProvider)
          .where((meetup) => meetup.placeName == '카페 테스트')
          .toList();
      expect(made, hasLength(1));
      // 연 사람은 가는 사람이다. 0으로 시작하면 방금 만든 자리가 아무도
      // 안 오는 곳처럼 보인다.
      expect(made.single.sessions.single.isJoined, isTrue);
      expect(made.single.sessions.single.participantCount, 1);
    });

    testWidgets('정원은 최소 인원 밑으로 내려가지 않는다', (tester) async {
      await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();
      await pickThirdDay(tester);

      // 8 에서 계속 줄여도 2 에서 멈춘다. 혼자 하는 모각코는 모임이 아니다.
      final minus = find.byIcon(Icons.remove);
      await tester.ensureVisible(minus);
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        await tester.tap(minus);
        await tester.pumpAndSettle();
      }

      expect(capacity('2'), findsOneWidget);
    });
  });
}
