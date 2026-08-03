import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/settings_group.dart';
import '../domain/app_notification.dart';
import 'notification_icon.dart';
import 'notification_settings_provider.dart';

/// 알림 설정.
///
/// 맨 위 하나로 전부 끄고, 아래에서 종류별로 고른다. 다 끄고 싶은 사람이
/// 다섯 개를 하나씩 내리게 두지 않는다.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(notificationSettingsProvider);
    final anyOn = ref.watch(anyNotificationOnProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return DetailScaffold(
      title: '알림 설정',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: CupertinoIcons.bell,
                    label: '알림 받기',
                    trailing: Switch.adaptive(
                      value: anyOn,
                      onChanged: (value) {
                        Haptics.toggle();
                        notifier.setAll(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // 전체를 끈 상태에서 종류별 스위치를 그대로 두면 켜도 아무 일이
              // 안 난다. 흐리게 낮춰 지금은 소용없다는 걸 먼저 알린다.
              Opacity(
                opacity: anyOn ? 1 : 0.4,
                child: IgnorePointer(
                  ignoring: !anyOn,
                  child: SettingsGroup(
                    key: const Key('kind-switches'),
                    title: '받을 알림',
                    children: [
                      for (final kind in NotificationKind.values)
                        SettingsTile(
                          icon: notificationIcon(kind),
                          label: kind.label,
                          description: kind.description,
                          trailing: Switch.adaptive(
                            value: on.contains(kind),
                            onChanged: (value) {
                              Haptics.toggle();
                              notifier.set(kind, value);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                child: Text(
                  '기기 설정에서 모각코 알림을 꺼두면 여기서 켜도 오지 않아요',
                  style: context.texts.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
