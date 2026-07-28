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
                  const SizedBox(height: AppSpacing.xxl),
                  MeetupCarousel(
                    meetups: meetups,
                    onToggleJoin: (id) =>
                        ref.read(meetupListProvider.notifier).toggleJoin(id),
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
