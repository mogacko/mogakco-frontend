import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/tag_chip.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../member/domain/member.dart';
import 'my_activity_screen.dart';
import 'profile_provider.dart';

/// 내 정보 탭.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(profileProvider);
    final now = ref.watch(nowProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: '내 정보',
              actions: [
                HeaderAction(
                  icon: CupertinoIcons.settings,
                  label: '설정',
                  onTap: () => context.push(AppRoute.settings),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: AppBottomNav.contentInset(context) + AppSpacing.xl,
                ),
                children: [
                  _Identity(profile: profile, now: now),
                  const SizedBox(height: AppSpacing.xl),
                  const _Stats(),
                  if (profile.stacks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _TagSection(
                      title: '스택',
                      tags: profile.stacks,
                      tone: TagTone.brand,
                    ),
                  ],
                  if (profile.interests.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _TagSection(title: '관심분야', tags: profile.interests),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),
                  const _EditProfileButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 누구인지.
///
/// 사진·닉네임 다음에 지역·분야·소속을 한 줄로 잇는다. 각각을 따로 세우면
/// 라벨 붙은 표가 되어 프로필이 서류처럼 보인다.
class _Identity extends StatelessWidget {
  const _Identity({required this.profile, required this.now});

  final Member profile;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final meta = [
      profile.chapter.label,
      profile.field,
      if (profile.affiliation != null) profile.affiliation!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                name: profile.nickname,
                imageUrl: profile.avatarUrl,
                size: 64,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.headlineMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${profile.daysSinceJoin(now)}일째 함께하는 중',
                      style: context.texts.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.bio != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              profile.bio!,
              style: context.texts.bodyMedium?.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 내 활동 요약.
///
/// 셋을 한 상자에 담고 사이를 선으로 나눈다. 따로 세우면 무엇끼리 견주는
/// 숫자인지 흐려진다.
class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final stats = ref.watch(profileStatsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        // 다크에서만 보이는 선.
        border: Border.all(color: colors.cardBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 숫자만 두면 무엇이 세어졌는지 확인할 길이 없다. 눌러서 목록을
            // 연다.
            _StatCell(
              kind: MyActivityKind.meetups,
              label: '참여 중인 모각코',
              value: stats.joinedMeetups,
            ),
            const _StatDivider(),
            _StatCell(
              kind: MyActivityKind.events,
              label: '신청한 행사',
              value: stats.appliedEvents,
            ),
            const _StatDivider(),
            _StatCell(
              kind: MyActivityKind.posts,
              label: '작성한 글',
              value: stats.posts,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.kind,
    required this.label,
    required this.value,
  });

  final MyActivityKind kind;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => context.push(AppRoute.myActivity(kind)),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          children: [
            Text(
              '$value',
              style: context.texts.headlineMedium?.copyWith(
                // 0은 아직 아무것도 안 한 상태다. 다른 숫자와 같은 무게로 두면
                // 비어 있다는 게 눈에 띄지 않는다.
                color: value == 0
                    ? context.colors.textTertiary
                    : context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: context.texts.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      indent: AppSpacing.xs,
      endIndent: AppSpacing.xs,
      color: context.colors.border,
    );
  }
}

/// 스택·관심분야처럼 태그가 늘어서는 구획
class _TagSection extends StatelessWidget {
  const _TagSection({
    required this.title,
    required this.tags,
    this.tone = TagTone.neutral,
  });

  final String title;
  final List<String> tags;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.texts.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final tag in tags) TagChip(label: tag, tone: tone)],
          ),
        ],
      ),
    );
  }
}

/// 프로필 수정으로 가는 버튼.
///
/// 설정 안이 아니라 프로필 아래에 둔다. 지금 보고 있는 것을 고치러 가는
/// 길이라, 무엇을 고치게 되는지가 바로 위에 있는 편이 짧다.
class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push(AppRoute.profileEdit),
              child: const Text('프로필 수정'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.push(AppRoute.myEvents),
              child: const Text('내가 올린 행사'),
            ),
          ),
        ],
      ),
    );
  }
}
