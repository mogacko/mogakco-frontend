import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/mogacko_logo.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../meetup/domain/meetup.dart';
import '../../../meetup/presentation/meetup_provider.dart';
import '../../../meetup/presentation/widgets/join_confirm_sheet.dart';

/// 모집 중인 모임을 옆으로 넘겨 보는 캐러셀.
class MeetupCarousel extends StatefulWidget {
  const MeetupCarousel({
    super.key,
    required this.meetups,
    required this.now,
    required this.onToggleSession,
  });

  /// 모임과 화면에 세울 하루.
  ///
  /// 한 모임이 여러 날에 걸쳐도 여기서는 하루만 다룬다. 갈지 말지를 하루로
  /// 좁혀야 결정이 단순해진다.
  final List<MeetupOnDay> meetups;

  /// '오늘/내일'을 재는 기준 시각
  final DateTime now;

  /// (모임 id, 날짜 id)로 그 날의 참여를 뒤집는다.
  final void Function(String meetupId, String sessionId) onToggleSession;

  @override
  State<MeetupCarousel> createState() => _MeetupCarouselState();
}

class _MeetupCarouselState extends State<MeetupCarousel> {
  static const _cardHeight = 210.0;

  /// 1보다 작게 둬야 양옆 카드가 걸쳐 보인다. 첫 장에서도 왼쪽에 이전 카드
  /// 끝자락이 남아 목록이 이어진다는 게 드러난다.
  ///
  /// 이웃 카드는 '더 있다'만 알리면 되므로 끝자락만 남기고 본 카드를 넓게 쓴다.
  static const _viewportFraction = 0.9;

  /// 끝없이 넘기는 것처럼 보이게 하려고 몇 바퀴 앞선 자리에서 시작한다.
  ///
  /// 실제로 무한한 목록을 만드는 대신 먼 페이지에서 출발하고 인덱스를 항목
  /// 수로 나눈 나머지에 대응시킨다. 양쪽으로 수천 번 넘겨도 끝에 닿지 않는다.
  static const _loopLaps = 3000;

  /// 순환 시작 페이지.
  ///
  /// 항목 수의 배수여야 첫 화면에 0번 카드가 온다. 고정 숫자를 쓰면
  /// 항목이 3개일 때 10000 % 3 = 1 이 되어 두 번째 카드부터 보인다.
  int get _loopStart => widget.meetups.length * _loopLaps;

  /// 순환하지 않을 때 먼 페이지에서 시작하면 범위를 벗어나 아무것도 안 보인다.
  late final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
    initialPage: _looping ? _loopStart : 0,
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
      _controller.jumpToPage(_looping ? _loopStart : 0);
      setState(() => _page = 0);
    }
  }

  /// 담긴 모임과 그 순서가 같은지
  bool _sameLineup(List<MeetupOnDay> before, List<MeetupOnDay> after) {
    if (before.length != after.length) return false;
    for (var i = 0; i < before.length; i++) {
      if (before[i].meetup.id != after[i].meetup.id) return false;
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _cardHeight,
          child: PageView.builder(
            controller: _controller,
            // null이면 양방향으로 끝없이 이어진다.
            itemCount: _looping ? null : count,
            onPageChanged: (index) => setState(() => _page = index % count),
            itemBuilder: (context, index) {
              final entry = widget.meetups[index % count];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: _MeetupCard(
                  // 순환하면 같은 카드가 여러 자리에 나타나므로 어느 모임인지
                  // 키로 짚을 수 있게 한다.
                  key: ValueKey(entry.meetup.id),
                  meetup: entry.meetup,
                  session: entry.session,
                  now: widget.now,
                  onToggle: () =>
                      widget.onToggleSession(entry.meetup.id, entry.session.id),
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
    required this.session,
    required this.now,
    required this.onToggle,
  });

  final Meetup meetup;

  /// 이 카드가 다루는 하루
  final MeetupSession session;

  final DateTime now;
  final VoidCallback onToggle;

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
                  // 위쪽 한 줄에 어디서·언제를 나란히 둔다.
                  // 왼쪽은 장소, 오른쪽은 시각과 정원이다.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _Place(meetup: meetup)),
                      const SizedBox(width: AppSpacing.md),
                      _When(session: session, now: now),
                    ],
                  ),
                  const Spacer(),
                  // 아래 줄은 누가 열었는지와 결정 버튼이 나눠 갖는다.
                  // 버튼은 엄지가 닿는 오른쪽에 둔다.
                  Row(
                    children: [
                      Expanded(
                        child: _Host(
                          name: meetup.host,
                          avatarUrl: meetup.hostAvatarUrl,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _JoinButton(
                        session: session,
                        onTap: () async {
                          final ok = await confirmJoinChange(
                            context,
                            meetup: meetup,
                            session: session,
                            now: now,
                          );
                          if (ok) onToggle();
                        },
                      ),
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

/// 카드 좌측 상단의 장소
class _Place extends StatelessWidget {
  const _Place({required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meetup.placeName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.texts.headlineMedium?.copyWith(color: Colors.white),
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
      ],
    );
  }
}

/// 카드 좌측 하단의 모임장
class _Host extends StatelessWidget {
  const _Host({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(
          name: name,
          imageUrl: avatarUrl,
          size: 24,
          // 카드가 파란 그라디언트라 흰 반투명 원이 배경 위에서 도드라진다.
          background: Colors.white.withValues(alpha: 0.24),
          foreground: Colors.white,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

/// 카드 우측 상단의 시각과 정원
class _When extends StatelessWidget {
  const _When({required this.session, required this.now});

  final MeetupSession session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          session.whenLabel(now),
          style: context.texts.labelLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.person_fill,
              size: AppSize.iconSm - 2,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 3),
            Text(
              '${session.participantCount} / ${session.capacity}',
              style: context.texts.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 좌측 하단 참여 토글
class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.session, required this.onTap});

  final MeetupSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final joined = session.isJoined;
    // 자리가 찼어도 이미 신청했다면 뺄 수는 있어야 한다.
    final blocked = session.isFull && !joined;

    // 신청을 마친 뒤에는 그 사실을 알리기만 하면 된다. '참여 취소'라고 써 두면
    // 다음에 할 일이 취소인 것처럼 읽힌다. 취소는 눌렀을 때 시트에서 묻는다.
    final label = blocked ? '마감' : (joined ? '참여 중' : '참여 신청');
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
            Icon(CupertinoIcons.calendar, size: 32, color: colors.textTertiary),
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
