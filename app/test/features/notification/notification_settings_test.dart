import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/notification/domain/app_notification.dart';
import 'package:mogacko/features/notification/presentation/notification_settings_provider.dart';
import 'package:mogacko/features/notification/presentation/notification_settings_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('알림 설정', () {
    testWidgets('처음에는 다 켜져 있다', (tester) async {
      final container = await tester.pumpScreen(
        const NotificationSettingsScreen(),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(notificationSettingsProvider),
        NotificationKind.values.toSet(),
      );
      // 종류마다 한 줄 + 맨 위 전체 스위치
      expect(
        find.byType(Switch),
        findsNWidgets(NotificationKind.values.length + 1),
      );
    });

    testWidgets('맨 위를 끄면 전부 꺼진다', (tester) async {
      final container = await tester.pumpScreen(
        const NotificationSettingsScreen(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(container.read(notificationSettingsProvider), isEmpty);
      expect(container.read(anyNotificationOnProvider), isFalse);
    });

    testWidgets('하나만 끄면 나머지는 남는다', (tester) async {
      final container = await tester.pumpScreen(
        const NotificationSettingsScreen(),
      );
      await tester.pumpAndSettle();

      container
          .read(notificationSettingsProvider.notifier)
          .set(NotificationKind.like, false);
      await tester.pumpAndSettle();

      final on = container.read(notificationSettingsProvider);
      expect(on.contains(NotificationKind.like), isFalse);
      expect(on.contains(NotificationKind.comment), isTrue);
      // 하나 껐다고 전체가 꺼진 것은 아니다.
      expect(container.read(anyNotificationOnProvider), isTrue);
    });

    testWidgets('다 끈 뒤 맨 위를 켜면 전부 돌아온다', (tester) async {
      final container = await tester.pumpScreen(
        const NotificationSettingsScreen(),
      );
      await tester.pumpAndSettle();

      container.read(notificationSettingsProvider.notifier).setAll(false);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(
        container.read(notificationSettingsProvider),
        NotificationKind.values.toSet(),
      );
    });

    testWidgets('전체를 끄면 종류별 스위치는 눌리지 않는다', (tester) async {
      final container = await tester.pumpScreen(
        const NotificationSettingsScreen(),
      );
      await tester.pumpAndSettle();

      container.read(notificationSettingsProvider.notifier).setAll(false);
      await tester.pumpAndSettle();

      // 켜도 아무 일이 안 나는 스위치를 누를 수 있게 두지 않는다.
      final gate = tester.widget<IgnorePointer>(
        find
            .ancestor(
              of: find.byKey(const Key('kind-switches')),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      expect(gate.ignoring, isTrue);
    });
  });
}
