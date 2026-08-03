import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/shared/data/mock_delay.dart';
import 'package:mogacko/shared/widgets/static_map.dart';
import 'package:mogacko/features/meetup/presentation/meetup_create_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/shared/providers/now_provider.dart';
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

    /// 오늘부터 이레가 알약으로 놓인다. [offset]일 뒤 칸을 누른다.
    Future<void> pickDay(
      WidgetTester tester,
      ProviderContainer container, {
      int offset = 2,
    }) async {
      final now = container.read(nowProvider);
      final day = DateTime(now.year, now.month, now.day + offset);
      await tester.tap(find.byKey(ValueKey(day)));
      await tester.pumpAndSettle();
    }

    /// 장소를 검색해서 첫 결과를 고른다.
    Future<void> pickPlace(WidgetTester tester, [String keyword = '모모스']) async {
      await tester.enterText(find.byType(TextField).first, keyword);
      // 디바운스 250ms + 목업 왕복.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(mockNetworkDelay);
      await tester.pumpAndSettle();

      await tester.tap(find.text('모모스커피 온천장'));
      await tester.pumpAndSettle();
    }

    testWidgets('장소와 날짜가 다 차야 만들 수 있다', (tester) async {
      await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      final button = find.widgetWithText(FilledButton, '만들기');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await pickPlace(tester);
      // 날짜가 없으면 아직 열리지 않는다. 언제 모이는지 없는 모임은 없다.
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });

    testWidgets('장소를 고르면 이름과 지도가 함께 뜬다', (tester) async {
      await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      expect(find.byType(StaticMap), findsNothing);

      await pickPlace(tester);

      expect(find.text('모모스커피 온천장'), findsOneWidget);
      expect(find.text('부산광역시 동래구 금강공원로 73번길 1'), findsOneWidget);
      // 검색창은 사라지고 고른 곳만 남는다. 무엇을 골랐는지가 화면에 하나여야 한다.
      expect(find.byType(StaticMap), findsOneWidget);
    });

    testWidgets('변경을 누르면 다시 검색할 수 있다', (tester) async {
      await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      await pickPlace(tester);
      await tester.tap(find.text('변경'));
      await tester.pumpAndSettle();

      expect(find.byType(StaticMap), findsNothing);
      expect(find.text('모모스커피 온천장'), findsNothing);
    });

    testWidgets('두 글자가 안 되면 찾지 않는다', (tester) async {
      await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '모');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('모모스커피 온천장'), findsNothing);
      expect(find.textContaining('글자 이상'), findsOneWidget);
    });

    testWidgets('날짜를 고르면 그 날의 시각과 정원 줄이 생긴다', (tester) async {
      final container = await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      expect(find.text('19:00'), findsNothing);

      await pickDay(tester, container);

      // 첫 날은 기본값으로 채워진다. 매번 고르게 두지 않는다.
      expect(find.text('19:00'), findsOneWidget);
      expect(capacity('8'), findsOneWidget);
    });

    testWidgets('여러 날을 한 모임으로 묶는다', (tester) async {
      final container = await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      await pickDay(tester, container, offset: 2);
      await pickDay(tester, container, offset: 3);

      // 두 줄 모두 직전 값을 이어받는다.
      expect(find.text('19:00'), findsNWidgets(2));
    });

    testWidgets('다시 누르면 그 날이 빠진다', (tester) async {
      final container = await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      await pickDay(tester, container);
      expect(find.text('19:00'), findsOneWidget);

      await pickDay(tester, container);
      expect(find.text('19:00'), findsNothing);
    });

    testWidgets('만들면 목록에 그 자리가 생기고 내가 참여 중이다', (tester) async {
      final container = await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();

      await pickPlace(tester);
      await pickDay(tester, container);

      await tester.tap(find.widgetWithText(FilledButton, '만들기'));
      await tester.pumpAndSettle();

      // 목업에도 같은 카페가 있다. 이름이 아니라 방금 만든 것인지로 가른다.
      final made = container
          .read(meetupListProvider)
          .where((meetup) => meetup.id.startsWith(MeetupList.localPrefix))
          .toList();
      expect(made, hasLength(1));
      expect(made.single.placeName, '모모스커피 온천장');
      // 검색으로 고른 곳이라 좌표가 딸려 온다. 상세에서 지도가 바로 뜬다.
      expect(made.single.hasLocation, isTrue);
      // 연 사람은 가는 사람이다. 0으로 시작하면 방금 만든 자리가 아무도
      // 안 오는 곳처럼 보인다.
      expect(made.single.sessions.single.isJoined, isTrue);
      expect(made.single.sessions.single.participantCount, 1);
    });

    testWidgets('정원은 최소 인원 밑으로 내려가지 않는다', (tester) async {
      final container = await tester.pumpScreen(const MeetupCreateScreen());
      await tester.pumpAndSettle();
      await pickDay(tester, container);

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
