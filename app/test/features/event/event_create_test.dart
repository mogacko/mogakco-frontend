import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/event/domain/event.dart';
import 'package:mogacko/features/event/presentation/event_create_screen.dart';
import 'package:mogacko/features/event/presentation/event_provider.dart';
import 'package:mogacko/features/event/presentation/my_events_screen.dart';
import 'package:mogacko/features/member/presentation/member_provider.dart';
import 'package:mogacko/shared/data/mock_delay.dart';
import 'package:mogacko/shared/providers/now_provider.dart';
import 'package:mogacko/shared/widgets/empty_state.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('행사 올리기', () {
    /// 목업 장소를 검색해서 고른다.
    Future<void> pickPlace(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).at(2), '모모스');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(mockNetworkDelay);
      await tester.pumpAndSettle();
      await tester.tap(find.text('모모스커피 온천장'));
      await tester.pumpAndSettle();
    }

    testWidgets('이름·소개·장소·날짜가 다 차야 올릴 수 있다', (tester) async {
      await tester.pumpScreen(const EventCreateScreen());
      await tester.pumpAndSettle();

      final button = find.widgetWithText(FilledButton, '검토 요청');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, '렌더링 뜯어보기');
      await tester.enterText(find.byType(TextField).at(1), '같이 파헤쳐요');
      await tester.pumpAndSettle();
      await pickPlace(tester);

      // 날짜가 없으면 아직 열리지 않는다.
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });

    testWidgets('올리기 전에 검토를 거친다고 알린다', (tester) async {
      await tester.pumpScreen(const EventCreateScreen());
      await tester.pumpAndSettle();

      // 눌러놓고 목록에 없으면 안 올라간 줄 안다.
      expect(find.textContaining('운영진 검토'), findsOneWidget);
    });

    testWidgets('검토 중인 행사는 목록에 서지 않는다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final now = container.read(nowProvider);
      final me = container.read(myIdProvider);
      final before = container.read(chapterEventsProvider).length;

      container
          .read(eventListProvider.notifier)
          .propose(
            Event(
              id: '${EventList.localPrefix}1',
              chapter: container.read(chapterEventsProvider).first.chapter,
              kind: EventKind.seminar,
              title: '검토 중인 행사',
              summary: '아직 안 올라간 자리',
              venue: '모모스커피 온천장',
              startsAt: now.add(const Duration(days: 10)),
              endsAt: now.add(const Duration(days: 10, hours: 3)),
              applyBy: now.add(const Duration(days: 9)),
              capacity: 30,
              applicantCount: 0,
              status: EventStatus.pending,
              proposedBy: me,
            ),
          );

      // 아무나 열 수 있게 두면 홍보 글이 행사로 올라온다.
      expect(container.read(chapterEventsProvider).length, before);
      // 낸 사람은 자기 자리에서 볼 수 있어야 한다.
      expect(
        container.read(myEventsProvider).map((event) => event.title),
        contains('검토 중인 행사'),
      );
    });

    testWidgets('올린 행사가 새로고침으로 사라지지 않는다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final now = container.read(nowProvider);
      container
          .read(eventListProvider.notifier)
          .propose(
            Event(
              id: '${EventList.localPrefix}2',
              chapter: container.read(chapterEventsProvider).first.chapter,
              kind: EventKind.hackathon,
              title: '남아 있어야 하는 행사',
              summary: '본문',
              venue: '모모스커피 온천장',
              startsAt: now.add(const Duration(days: 20)),
              endsAt: now.add(const Duration(days: 20, hours: 3)),
              applyBy: now.add(const Duration(days: 19)),
              capacity: 30,
              applicantCount: 0,
              status: EventStatus.pending,
              proposedBy: container.read(myIdProvider),
            ),
          );

      final refreshed = container.read(eventListProvider.notifier).refresh();
      await tester.pump(mockNetworkDelay);
      await refreshed;

      expect(
        container.read(myEventsProvider).map((event) => event.title),
        contains('남아 있어야 하는 행사'),
      );
    });
  });

  group('내가 올린 행사', () {
    testWidgets('없으면 올리라고 안내한다', (tester) async {
      await tester.pumpScreen(const MyEventsScreen());
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('행사 올리기'), findsOneWidget);
    });

    testWidgets('반려되면 사유가 상태 대신 보인다', (tester) async {
      final container = await tester.pumpScreen(const MyEventsScreen());
      await tester.pumpAndSettle();

      final now = container.read(nowProvider);
      container
          .read(eventListProvider.notifier)
          .propose(
            Event(
              id: '${EventList.localPrefix}3',
              chapter: container.read(chapterEventsProvider).first.chapter,
              kind: EventKind.other,
              title: '반려된 행사',
              summary: '본문',
              venue: '모모스커피 온천장',
              startsAt: now.add(const Duration(days: 30)),
              endsAt: now.add(const Duration(days: 30, hours: 3)),
              applyBy: now.add(const Duration(days: 29)),
              capacity: 30,
              applicantCount: 0,
              status: EventStatus.rejected,
              proposedBy: container.read(myIdProvider),
              rejectionNote: '홍보성 내용이 많아 반려했어요',
            ),
          );
      await tester.pumpAndSettle();

      // 왜 안 됐는지 없이 '반려됨'만 있으면 같은 걸 그대로 다시 올린다.
      expect(find.text('반려됨'), findsOneWidget);
      expect(find.text('홍보성 내용이 많아 반려했어요'), findsOneWidget);
    });
  });
}
