import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import 'meetup_provider.dart';
import 'widgets/home_header.dart';
import 'widgets/meetup_carousel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final meetups = ref.watch(heroMeetupsProvider);
    final now = ref.watch(nowProvider);
    final isToday = ref.watch(heroIsTodayProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HomeHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.huge),
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  // 카드 하나가 아니라 이 구획 전체가 무엇인지 알린다.
                  // 그래서 카드가 아니라 화면 여백에 맞춰 세운다.
                  // 오늘 열리는 모임이 있으면 오늘 것만 세운다.
                  // 없는 날이 더 흔해서, 그때는 가장 가까운 날로 대신한다.
                  _SectionTitle(isToday ? '오늘의 모각코' : '다가오는 모각코'),
                  const SizedBox(height: AppSpacing.lg),
                  MeetupCarousel(
                    meetups: meetups,
                    now: now,
                    onToggleSession: (meetupId, sessionId) => ref
                        .read(meetupListProvider.notifier)
                        .toggleSession(meetupId, sessionId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 구획 제목.
///
/// 카드가 아니라 그 묶음이 무엇인지 말한다. 화면 여백에 맞춰 세워야
/// 다른 구획이 아래로 이어질 때 같은 줄에서 시작한다.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.calendar, size: 19, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: context.texts.headlineMedium),
        ],
      ),
    );
  }
}
