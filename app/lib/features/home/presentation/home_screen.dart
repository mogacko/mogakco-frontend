import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import 'meetup_provider.dart';
import 'widgets/flame_icon.dart';
import 'widgets/home_header.dart';
import 'widgets/meetup_carousel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final meetups = ref.watch(visibleMeetupsProvider);

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
                  MeetupCarousel(
                    meetups: meetups,
                    onToggleJoin: (id) =>
                        ref.read(meetupListProvider.notifier).toggleJoin(id),
                    // 카드가 왜 이 순서인지 알려주는 자리.
                    // 카드와 좌우를 맞춰야 해서 캐러셀에 맡긴다.
                    label: const _PopularLabel(),
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

/// 캐러셀이 인기순이라는 표시.
///
/// 제목이 아니라 라벨이다. 카드가 스스로 말하는 정보는 담지 않고
/// 정렬 기준만 짧게 알린다.
class _PopularLabel extends StatelessWidget {
  const _PopularLabel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        FlameIcon(color: colors.hot),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '지금 인기',
          style: context.texts.labelMedium?.copyWith(
            color: colors.hot,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
