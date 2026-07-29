import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 설정 항목 묶음.
///
/// iOS 설정 앱의 그룹 목록을 따른다. 항목마다 테두리를 두르는 대신 묶음
/// 하나를 면으로 세우고 안쪽만 얇은 선으로 나눈다. 어디까지가 한 묶음인지가
/// 선이 아니라 여백으로 읽힌다.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.title});

  /// 묶음 위에 붙는 작은 제목. 없으면 묶음만 놓인다.
  final String? title;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = this.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title,
              style: context.texts.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        // Material 로 세운다. 잉크 효과는 가장 가까운 Material 이 그 모양대로
        // 잘라 그리므로, 바깥에 ClipRRect 를 둘러도 눌린 자국이 둥근 모서리를
        // 삐져나온다.
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  // 선은 글자 시작점에 맞춰 들여 쓴다. 끝까지 그으면 묶음이
                  // 여러 칸으로 쪼개져 보인다.
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.lg),
                    child: Divider(height: 1, color: colors.border),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 설정 한 줄.
///
/// 누르면 어딘가로 가는 줄에는 오른쪽 화살표를, 그 자리에서 켜고 끄는 줄에는
/// [trailing] 을 넘긴다. 둘 다 없으면 아무 표시도 붙지 않아 정보 줄이 된다.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.tone = SettingsTone.normal,
  });

  final IconData icon;
  final String label;

  /// 오른쪽에 딸려 붙는 현재 값. '시스템 설정' 같은 것.
  final String? value;

  /// 스위치처럼 그 자리에서 다루는 조작. 넘기면 화살표 대신 이것이 붙는다.
  final Widget? trailing;

  final VoidCallback? onTap;
  final SettingsTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = this.value;
    final trailing = this.trailing;

    final foreground = switch (tone) {
      SettingsTone.normal => colors.textPrimary,
      SettingsTone.danger => colors.danger,
    };

    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            // 세로 14 + 아이콘 22 = 50. 손가락이 닿는 최소 크기(44)를 넘긴다.
            vertical: AppSpacing.lg - 2,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppSize.iconSm,
                color: tone == SettingsTone.danger
                    ? colors.danger
                    : colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: context.texts.bodyLarge?.copyWith(color: foreground),
                ),
              ),
              if (value != null)
                Text(
                  value,
                  style: context.texts.bodyMedium?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              if (trailing != null)
                trailing
              else if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: AppSize.iconSm - 4,
                  color: colors.textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum SettingsTone { normal, danger }
