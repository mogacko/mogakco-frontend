import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/providers/theme_mode_provider.dart';
import '../../../shared/widgets/confirm_sheet.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/option_sheet.dart';
import '../../../shared/widgets/settings_group.dart';
import '../../auth/presentation/session_provider.dart';
import '../../notification/presentation/notification_settings_provider.dart';
import '../../safety/presentation/safety_provider.dart';
import '../../signup/domain/term.dart';
import 'profile_provider.dart';

/// 설정.
///
/// 내 정보 탭에 늘어놓지 않고 따로 뺐다. 탭은 '나는 누구고 무엇을 했는가'를
/// 보는 자리인데, 그 아래에 설정 목록이 이어지면 프로필을 보러 들어와도
/// 설정을 먼저 지나야 한다.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmSheet(
      context,
      title: '로그아웃할까요?',
      confirmLabel: '로그아웃',
      tone: ConfirmTone.danger,
    );

    if (!ok) return;
    // 화면을 직접 옮기지 않는다. 세션이 비면 라우터가 로그인으로 돌린다.
    // 이동을 두 곳에서 정하면 언젠가 어긋난다.
    ref.read(sessionProvider.notifier).signOut();
  }

  Future<void> _pickThemeMode(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final picked = await showOptionSheet<ThemeMode>(
      context,
      title: '화면 모드',
      options: ThemeMode.values,
      selected: current,
      labelOf: (mode) => mode.label,
      descriptionOf: (mode) => mode.description,
    );

    if (picked == null) return;
    ref.read(themeModeProvider.notifier).select(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketing = ref.watch(marketingOptInProvider);
    final themeMode = ref.watch(themeModeProvider);
    final notificationsOn = ref.watch(anyNotificationOnProvider);
    final blockedCount = ref.watch(blockedProvider).length;

    return DetailScaffold(
      title: '설정',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsGroup(
                title: '앱',
                children: [
                  SettingsTile(
                    icon: CupertinoIcons.bell,
                    label: '알림',
                    // 들어가지 않고도 지금 받고 있는지 알 수 있어야 한다.
                    value: notificationsOn ? '받는 중' : '받지 않음',
                    onTap: () => context.push(AppRoute.notificationSettings),
                  ),
                  SettingsTile(
                    icon: CupertinoIcons.moon,
                    label: '화면 모드',
                    value: themeMode.label,
                    onTap: () => _pickThemeMode(context, ref, themeMode),
                  ),
                  SettingsTile(
                    icon: CupertinoIcons.nosign,
                    label: '차단한 사람',
                    // 차단은 상세 안쪽에서 하지만 푸는 자리는 여기다. 몇 명을
                    // 차단해 뒀는지도 들어가지 않고 알 수 있어야 한다.
                    value: blockedCount == 0 ? null : '$blockedCount명',
                    onTap: () => context.push(AppRoute.blockedMembers),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SettingsGroup(
                title: '약관',
                children: [
                  for (final term in [Term.service, Term.privacy])
                    SettingsTile(
                      icon: CupertinoIcons.doc_text,
                      label: term.title,
                      onTap: () => context.push(AppRoute.term(term)),
                    ),
                  SettingsTile(
                    icon: CupertinoIcons.envelope,
                    label: Term.marketing.title,
                    trailing: Switch.adaptive(
                      value: marketing,
                      onChanged: (value) =>
                          ref.read(marketingOptInProvider.notifier).set(value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SettingsGroup(
                children: [
                  SettingsTile(
                    icon: CupertinoIcons.square_arrow_left,
                    label: '로그아웃',
                    tone: SettingsTone.danger,
                    onTap: () => _logout(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
