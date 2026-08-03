import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';

import '../domain/app_notification.dart';

/// 알림 종류를 가리키는 아이콘.
///
/// 목록과 설정이 같은 모양을 써야 한다. 설정에서 끈 것이 목록에서 어느 줄인지
/// 아이콘으로 이어지지 않으면 무엇을 껐는지 되짚을 수 없다.
IconData notificationIcon(NotificationKind kind) => switch (kind) {
  NotificationKind.comment => CupertinoIcons.chat_bubble,
  NotificationKind.like => CupertinoIcons.heart,
  NotificationKind.join => CupertinoIcons.person_add,
  NotificationKind.upcoming => CupertinoIcons.clock,
  NotificationKind.notice => CupertinoIcons.speaker_2,
};
