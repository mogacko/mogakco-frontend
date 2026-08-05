import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/now_provider.dart';
import '../../../shared/utils/haptics.dart';
import '../../../shared/widgets/confirm_sheet.dart';
import '../../../shared/widgets/detail_scaffold.dart';
import '../../auth/presentation/session_provider.dart';
import '../../community/presentation/post_provider.dart';
import '../../meetup/presentation/meetup_provider.dart';
import 'profile_provider.dart';

/// 회원 탈퇴.
///
/// 설정 맨 아래 한 줄로 두고 여기서 무슨 일이 일어나는지 다 밝힌다. 확인
/// 시트만으로 끝내면 '정말요?' 한 번 누르고 계정이 사라지는데, 그건 되돌릴
/// 수 없는 일치고는 너무 가볍다.
class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  /// 읽었다고 눌러야 버튼이 열린다.
  bool _agreed = false;

  Future<void> _withdraw() async {
    final ok = await showConfirmSheet(
      context,
      title: '정말 탈퇴할까요?',
      details: Text(
        '계정과 활동 기록이 지워지고 되돌릴 수 없어요.',
        style: context.texts.bodyMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      confirmLabel: '탈퇴',
      tone: ConfirmTone.danger,
    );
    if (!ok) return;

    Haptics.decide();
    // 화면을 직접 옮기지 않는다. 세션이 비면 라우터가 로그인으로 돌린다.
    ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final profile = ref.watch(profileProvider);
    final now = ref.watch(nowProvider);

    final hosting = ref
        .watch(meetupListProvider)
        .where((meetup) => meetup.host == profile.nickname)
        .where((meetup) => !meetup.isCancelled)
        .where((meetup) => meetup.nextSession(now) != null)
        .length;
    final posts = ref
        .watch(postFeedProvider)
        .where((post) => post.author == profile.nickname)
        .length;

    return DetailScaffold(
      title: '회원 탈퇴',
      bottomAction: FilledButton(
        onPressed: _agreed ? _withdraw : null,
        style: FilledButton.styleFrom(backgroundColor: colors.danger),
        child: const Text('탈퇴하기'),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${profile.nickname}님, 정말 떠나시나요?',
                style: context.texts.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${profile.daysSinceJoin(now)}일째 함께했어요',
                style: context.texts.labelSmall,
              ),
              const SizedBox(height: AppSpacing.xxl),
              // 열어 둔 자리가 있으면 그것부터 알린다. 탈퇴하고 나서 오기로
              // 했던 사람들이 빈 카페에 모이는 일이 생기면 안 된다.
              if (hosting > 0) ...[
                _Notice(
                  icon: CupertinoIcons.exclamationmark_triangle,
                  tone: colors.danger,
                  text: '아직 열려 있는 모각코가 $hosting개 있어요. 탈퇴하기 전에 접어주세요.',
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              _Item('계정과 프로필이 지워지고 되돌릴 수 없어요'),
              _Item(
                posts > 0
                    ? '쓴 글 $posts개와 댓글이 함께 지워져요'
                    : '쓴 글과 댓글이 함께 지워져요',
              ),
              _Item('참여하기로 한 모각코와 행사 신청이 모두 취소돼요'),
              _Item('같은 닉네임으로 다시 가입할 수 있지만 기록은 돌아오지 않아요'),
              const SizedBox(height: AppSpacing.xxl),
              CheckboxListTile.adaptive(
                value: _agreed,
                onChanged: (value) {
                  Haptics.toggle();
                  setState(() => _agreed = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  '위 내용을 모두 확인했어요',
                  style: context.texts.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 지워지는 것 한 줄.
class _Item extends StatelessWidget {
  const _Item(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: context.texts.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.tone, required this.text});

  final IconData icon;
  final Color tone;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(left: BorderSide(color: tone, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSize.iconSm, color: tone),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: context.texts.bodyMedium?.copyWith(
                color: colors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
