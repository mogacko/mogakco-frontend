import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/mogacko_logo.dart';
import '../../domain/meetup.dart';

/// 모집 중인 모임을 옆으로 넘겨 보는 캐러셀.
class MeetupCarousel extends StatefulWidget {
  const MeetupCarousel({
    super.key,
    required this.meetups,
    required this.onToggleJoin,
  });

  final List<Meetup> meetups;
  final ValueChanged<String> onToggleJoin;

  @override
  State<MeetupCarousel> createState() => _MeetupCarouselState();
}

class _MeetupCarouselState extends State<MeetupCarousel> {
  static const _cardHeight = 210.0;

  /// 1보다 작게 둬야 양옆 카드가 걸쳐 보인다. 첫 장에서도 왼쪽에 이전 카드
  /// 끝자락이 남아 목록이 이어진다는 게 드러난다.
  static const _viewportFraction = 0.82;

  /// 끝없이 넘기는 것처럼 보이게 하는 시작 지점.
  ///
  /// 실제로 무한한 목록을 만드는 대신 아주 먼 페이지에서 시작하고 인덱스를
  /// 항목 수로 나눈 나머지에 대응시킨다. 양쪽으로 수천 번 넘겨도 끝에 닿지 않는다.
  static const _loopOrigin = 10000;

  /// 순환하지 않을 때 먼 페이지에서 시작하면 범위를 벗어나 아무것도 안 보인다.
  late final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
    initialPage: _looping ? _loopOrigin : 0,
  );

  int _page = 0;

  /// 한 장뿐이면 순환시켜도 같은 카드만 반복돼 의미가 없다.
  bool get _looping => widget.meetups.length > 1;

  @override
  void didUpdateWidget(MeetupCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 지역을 바꾸면 목록이 통째로 갈리므로 첫 장부터 다시 보여준다.
    //
    // 참여 상태만 바뀌어도 목록은 매번 새 인스턴스로 온다. 리스트를 그대로
    // 비교하면 참조가 달라 늘 리셋되고, 참여를 누른 순간 보던 카드가 첫 장으로
    // 튕긴다. 그래서 어떤 모임이 어떤 순서로 있는지만 본다.
    if (!_sameLineup(oldWidget.meetups, widget.meetups) &&
        _controller.hasClients) {
      _controller.jumpToPage(_looping ? _loopOrigin : 0);
      setState(() => _page = 0);
    }
  }

  /// 담긴 모임과 그 순서가 같은지
  bool _sameLineup(List<Meetup> before, List<Meetup> after) {
    if (before.length != after.length) return false;
    for (var i = 0; i < before.length; i++) {
      if (before[i].id != after[i].id) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.meetups.isEmpty) return const _EmptyState();

    final count = widget.meetups.length;

    return Column(
      children: [
        SizedBox(
          height: _cardHeight,
          child: PageView.builder(
            controller: _controller,
            // null이면 양방향으로 끝없이 이어진다.
            itemCount: _looping ? null : count,
            onPageChanged: (index) => setState(() => _page = index % count),
            itemBuilder: (context, index) {
              final meetup = widget.meetups[index % count];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: _MeetupCard(
                  // 순환하면 같은 카드가 여러 자리에 나타나므로 어느 모임인지
                  // 키로 짚을 수 있게 한다.
                  key: ValueKey(meetup.id),
                  meetup: meetup,
                  onToggleJoin: () => widget.onToggleJoin(meetup.id),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PageDots(count: count, current: _page),
      ],
    );
  }
}

class _MeetupCard extends StatelessWidget {
  const _MeetupCard({
    super.key,
    required this.meetup,
    required this.onToggleJoin,
  });

  final Meetup meetup;
  final VoidCallback onToggleJoin;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandBlue,
            Color.lerp(AppColors.brandBlue, const Color(0xFF7C4DFF), 0.45)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            // 로고를 크게 흐리게 깔아 카드가 밋밋해지지 않게 한다.
            Positioned(
              right: -20,
              top: -16,
              child: Opacity(
                opacity: 0.13,
                child: MogackoLogo.square(
                  size: 132,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    meetup.placeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    meetup.shortAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      _JoinButton(meetup: meetup, onTap: onToggleJoin),
                      const Spacer(),
                      _Participants(meetup: meetup),
                    ],
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

/// 좌측 하단 참여 토글
class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.meetup, required this.onTap});

  final Meetup meetup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final joined = meetup.isJoined;
    // 정원이 찼어도 이미 신청했다면 취소는 할 수 있어야 한다.
    final blocked = meetup.isFull && !joined;

    final label = blocked ? '마감' : (joined ? '참여 취소' : '참여 신청');
    final background = blocked
        ? Colors.white.withValues(alpha: 0.16)
        : (joined ? Colors.transparent : Colors.white);
    final foreground = blocked
        ? Colors.white.withValues(alpha: 0.55)
        : (joined ? Colors.white : AppColors.brandBlue);

    return Semantics(
      button: true,
      selected: joined,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: joined && !blocked
              ? BorderSide(color: Colors.white.withValues(alpha: 0.75))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: blocked ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md - 1,
            ),
            child: Text(
              label,
              style: context.texts.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Participants extends StatelessWidget {
  const _Participants({required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.person,
          size: AppSize.iconSm,
          color: Colors.white.withValues(alpha: 0.85),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${meetup.participantCount} / ${meetup.capacity}',
          style: context.texts.labelMedium?.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == current ? colors.primary : colors.border,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 210,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 32, color: colors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              '아직 열린 모임이 없어요',
              style: context.texts.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
