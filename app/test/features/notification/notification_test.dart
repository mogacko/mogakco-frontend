import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/notification/presentation/notification_provider.dart';
import 'package:mogacko/features/notification/presentation/notification_screen.dart';
import 'package:mogacko/shared/data/mock_delay.dart';
import 'package:mogacko/shared/domain/chapter.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('알림', () {
    testWidgets('지금 지역의 알림만 보인다', (tester) async {
      await tester.pumpScreen(const NotificationScreen());
      await tester.pumpAndSettle();

      expect(find.text('해달님이 회원님의 글에 댓글을 달았어요'), findsOneWidget);
      // 서울 알림은 부산에서 보이지 않는다. 지역이 갈리는 커뮤니티라
      // 남의 지부 소식이 섞이면 알림이 소음이 된다.
      expect(find.text('민트님이 회원님의 글에 댓글을 달았어요'), findsNothing);
    });

    testWidgets('지역을 바꾸면 그 지역 알림이 보인다', (tester) async {
      await tester.pumpScreen(
        const NotificationScreen(),
        chapter: Chapter.seoul,
      );
      await tester.pumpAndSettle();

      expect(find.text('민트님이 회원님의 글에 댓글을 달았어요'), findsOneWidget);
    });

    testWidgets('안 읽은 것이 있으면 모두 읽음이 뜬다', (tester) async {
      final container = await tester.pumpScreen(const NotificationScreen());
      await tester.pumpAndSettle();

      expect(container.read(hasUnreadProvider), isTrue);
      expect(find.text('모두 읽음'), findsOneWidget);

      await tester.tap(find.text('모두 읽음'));
      await tester.pumpAndSettle();

      expect(container.read(hasUnreadProvider), isFalse);
      // 다 읽고 나면 누를 것이 없다. 눌러도 아무 일 없는 버튼을 남기지 않는다.
      expect(find.text('모두 읽음'), findsNothing);
    });

    testWidgets('하나를 누르면 그것만 읽음이 된다', (tester) async {
      final container = await tester.pumpScreen(const NotificationScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('해달님이 회원님의 글에 댓글을 달았어요'));
      await tester.pumpAndSettle();

      final items = container.read(notificationListProvider);
      expect(items.firstWhere((item) => item.id == 'busan-n1').isRead, isTrue);
      expect(items.firstWhere((item) => item.id == 'busan-n3').isRead, isFalse);
    });

    testWidgets('새로고침해도 읽음 표시가 지켜진다', (tester) async {
      final container = await tester.pumpScreen(const NotificationScreen());
      await tester.pumpAndSettle();

      container.read(notificationListProvider.notifier).markRead('busan-n1');

      final refreshed = container
          .read(notificationListProvider.notifier)
          .refresh();
      await tester.pump(mockNetworkDelay);
      await refreshed;

      final items = container.read(notificationListProvider);
      expect(items.firstWhere((item) => item.id == 'busan-n1').isRead, isTrue);
    });

    testWidgets('최신이 위에 온다', (tester) async {
      final container = await tester.pumpScreen(const NotificationScreen());
      await tester.pumpAndSettle();

      final items = container.read(chapterNotificationsProvider);
      for (var i = 1; i < items.length; i++) {
        expect(
          items[i - 1].createdAt.isAfter(items[i].createdAt),
          isTrue,
          reason: '${items[i - 1].id} 가 ${items[i].id} 보다 뒤에 있다',
        );
      }
    });
  });

  group('알림 종', () {
    testWidgets('안 읽은 것이 없으면 점이 사라진다', (tester) async {
      final container = await tester.pumpScreen(const NotificationScreen());
      await tester.pumpAndSettle();

      expect(container.read(hasUnreadProvider), isTrue);

      container.read(notificationListProvider.notifier).markAllRead();
      await tester.pumpAndSettle();

      expect(container.read(hasUnreadProvider), isFalse);
    });
  });
}
