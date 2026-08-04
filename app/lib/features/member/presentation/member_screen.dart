import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/tag_chip.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../domain/member.dart';
import 'member_provider.dart';

/// 남의 프로필.
///
/// 공개해도 되는 것만 둔다. 내 정보 탭에 있는 활동 요약(참여 중인 모각코,
/// 신청한 행사)은 여기 없다 — 남이 어디에 가는지까지 훑을 수 있으면 그건
/// 프로필이 아니라 추적이다.
class MemberScreen extends ConsumerWidget {
  const MemberScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberProvider(memberId));

    if (member == null) {
      return const DetailScaffold(
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.huge),
            child: EmptyState(
              icon: CupertinoIcons.person,
              title: '찾을 수 없는 사람이에요',
              description: '탈퇴했거나 잘못된 주소일 수 있어요',
            ),
          ),
        ],
      );
    }

    final isMe = memberId == ref.watch(myIdProvider);

    return DetailScaffold(
      children: [
        _Identity(member: member, isMe: isMe),
        if (member.stacks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          _TagSection(title: '스택', tags: member.stacks, tone: TagTone.brand),
        ],
        if (member.interests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _TagSection(title: '관심분야', tags: member.interests),
        ],
      ],
    );
  }
}

class _Identity extends ConsumerWidget {
  const _Identity({required this.member, required this.isMe});

  final Member member;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = ref.watch(nowProvider);

    // 운영진은 지역·분야를 적지 않는다. 사람이 아니라 자리라서, 소속을 적으면
    // 어느 지부 담당인지를 두고 오해가 생긴다.
    final meta = member.isStaff
        ? '지부 운영진'
        : [
            member.chapter.label,
            member.field,
            if (member.affiliation != null) member.affiliation!,
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
                name: member.nickname,
                imageUrl: member.avatarUrl,
                size: 64,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.headlineMedium,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text('나', style: context.texts.labelSmall),
                        ],
                      ],
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
                      '${member.daysSinceJoin(now)}일째 함께하는 중',
                      style: context.texts.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (member.bio != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              member.bio!,
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
            children: [
              for (final tag in tags) TagChip(label: tag, tone: tone),
            ],
          ),
        ],
      ),
    );
  }
}
