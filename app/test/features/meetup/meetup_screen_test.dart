import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/meetup/presentation/meetup_screen.dart';
import 'package:mogacko/shared/widgets/filter_bar.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('MeetupScreen', () {
    /// '참여 중'은 필터 알약과 날짜 줄 양쪽에 나온다. 필터 쪽만 짚는다.
    Finder filterPill(String label) => find.descendant(
      of: find.byType(FilterBar<MeetupFilter>),
      matching: find.text(label),
    );

    testWidgets('한 모임의 여러 날을 한 카드에 함께 세운다', (tester) async {
      await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      expect(find.text('모각코'), findsOneWidget);
      // 부산 모임만 나온다.
      expect(find.text('모모스커피 온천장'), findsOneWidget);
      expect(find.text('카페 그리다'), findsNothing);
    });

    testWidgets('참여 중만 보면 신청한 모임만 남는다', (tester) async {
      await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      await tester.tap(filterPill('참여 중'));
      await tester.pumpAndSettle();

      // 목업에서 미리 신청해 둔 모임.
      expect(find.text('카페 오리진'), findsOneWidget);
      expect(find.text('모모스커피 온천장'), findsNothing);
    });

    testWidgets('정기 모임에는 표시가 붙는다', (tester) async {
      await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      await tester.tap(filterPill('정기'));
      await tester.pumpAndSettle();

      expect(find.text('정기'), findsWidgets);
      // 이번 주만 여는 모임은 빠진다.
      expect(find.text('웨이브온 커피'), findsNothing);
    });

    testWidgets('날짜 줄을 누르면 바로 신청되지 않고 확인을 먼저 받는다', (tester) async {
      await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('신청').first);
      await tester.pumpAndSettle();

      expect(find.text('이 일정으로 참여할까요?'), findsOneWidget);
    });

    testWidgets('확인해야 참여 상태가 바뀐다', (tester) async {
      await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      final before = find.text('참여 중').evaluate().length;

      await tester.tap(find.text('신청').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('참여하기'));
      await tester.pumpAndSettle();

      expect(find.text('참여 중').evaluate().length, before + 1);
    });

    testWidgets('물러나면 아무 일도 일어나지 않는다', (tester) async {
      await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      final before = find.text('참여 중').evaluate().length;

      await tester.tap(find.text('신청').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();

      expect(find.text('참여 중').evaluate().length, before);
    });
  });
}
