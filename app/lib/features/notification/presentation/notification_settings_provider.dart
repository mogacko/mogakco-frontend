import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_notification.dart';

/// 받을 알림 종류.
///
/// 기기에 남기지 않는다. 앱을 다시 켜면 전부 켜진 채로 시작한다. 서버에
/// 계정 설정이 붙을 때 함께 저장한다.
class NotificationSettings extends Notifier<Set<NotificationKind>> {
  @override
  Set<NotificationKind> build() => NotificationKind.values.toSet();

  void set(NotificationKind kind, bool on) {
    state = {
      for (final value in NotificationKind.values)
        if (value == kind ? on : state.contains(value)) value,
    };
  }

  /// 한 번에 다 끄고 켠다.
  void setAll(bool on) {
    state = on ? NotificationKind.values.toSet() : const {};
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettings, Set<NotificationKind>>(
      NotificationSettings.new,
    );

/// 하나라도 받고 있는지. 맨 위 스위치가 이 값을 쓴다.
final anyNotificationOnProvider = Provider<bool>((ref) {
  return ref.watch(notificationSettingsProvider).isNotEmpty;
});
