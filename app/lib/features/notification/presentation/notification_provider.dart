import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_delay.dart';
import '../../../shared/providers/current_chapter_provider.dart';
import '../../../shared/providers/now_provider.dart';
import '../data/mock_notifications.dart';
import '../domain/app_notification.dart';

/// 알림 목록과 읽음 상태.
class NotificationList extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    final now = ref.watch(nowProvider);
    return MockNotifications.from(now)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void markRead(String id) {
    state = [
      for (final item in state)
        if (item.id != id) item else item.markRead(),
    ];
  }

  void markAllRead() {
    state = [for (final item in state) item.markRead()];
  }

  /// 당겨서 새로고침.
  ///
  /// 읽음 표시는 지키고 목록만 다시 받는다. 서버가 붙으면 읽음도 응답에
  /// 실려 오므로 아래 옮겨 담기는 지운다.
  Future<void> refresh() async {
    final read = {
      for (final item in state)
        if (item.isRead) item.id,
    };

    await Future<void>.delayed(mockNetworkDelay);

    state =
        MockNotifications.from(ref.read(nowProvider))
            .map((item) => read.contains(item.id) ? item.markRead() : item)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

final notificationListProvider =
    NotifierProvider<NotificationList, List<AppNotification>>(
      NotificationList.new,
    );

/// 지금 보고 있는 지역의 알림.
final chapterNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final chapter = ref.watch(currentChapterProvider);
  return ref
      .watch(notificationListProvider)
      .where((item) => item.chapter == chapter)
      .toList();
});

/// 안 읽은 알림 개수.
///
/// 숫자는 안 쓰고 점만 찍는다. 헤더에 두 자리 숫자가 붙으면 그것부터 눈에
/// 들어오는데, 몇 개인지는 열어보면 알고 지금 필요한 건 있는지 없는지다.
final hasUnreadProvider = Provider<bool>((ref) {
  return ref.watch(chapterNotificationsProvider).any((item) => !item.isRead);
});
