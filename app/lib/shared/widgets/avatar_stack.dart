import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'user_avatar.dart';

/// 참여자 얼굴을 겹쳐 세운 줄.
///
/// '5 / 8'이라는 숫자만으로는 어떤 자리인지 알 수 없다. 얼굴이 몇 개 보이면
/// 사람이 모이는 자리라는 게 숫자보다 먼저 읽힌다.
///
/// 셋까지만 세우고 나머지는 마지막 칸에 +n 으로 접는다. 넷을 넘기면 카드 폭을
/// 먹기 시작하는데, 정작 얼굴이 작아져서 누구인지도 알아볼 수 없다.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.names,
    this.size = 28,
    this.max = 3,
    this.ringColor,
  });

  /// 세울 사람들. 앞에서부터 보인다.
  final List<String> names;

  /// 테두리를 포함한 한 칸의 지름.
  final double size;

  /// 얼굴로 세울 최대 인원. 나머지는 +n 으로 접힌다.
  final int max;

  /// 겹친 얼굴을 갈라놓는 테두리 색. 얼굴이 놓이는 바탕색과 같아야 뒤 얼굴을
  /// 파낸 것처럼 보인다. 없으면 카드 바탕색.
  final Color? ringColor;

  static const _ring = 2.0;

  /// 겹치는 정도. 지름의 3분의 1쯤 물리면 옆 얼굴을 가리지 않으면서도
  /// 한 덩어리로 읽힌다.
  double get _step => size - size / 3;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final shown = names.take(max).toList();
    final rest = names.length - shown.length;
    final slots = shown.length + (rest > 0 ? 1 : 0);
    final ring = ringColor ?? colors.surface;

    return SizedBox(
      width: size + (slots - 1) * _step,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _step,
              child: _Slot(
                size: size,
                ring: ring,
                child: UserAvatar(name: shown[i], size: size - _ring * 2),
              ),
            ),
          if (rest > 0)
            Positioned(
              left: shown.length * _step,
              child: _Slot(
                size: size,
                ring: ring,
                child: ColoredBox(
                  color: colors.surfaceAlt,
                  child: Center(
                    child: Text(
                      '+$rest',
                      style: context.texts.labelSmall?.copyWith(
                        // 얼굴 옆에 붙는 숫자다. 얼굴보다 도드라지면 안 된다.
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: size <= 28 ? 10 : 12,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.size, required this.ring, required this.child});

  final double size;
  final Color ring;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(AvatarStack._ring),
      decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
      child: ClipOval(child: child),
    );
  }
}

/// 얼굴 줄 + 'N명 참여 중' 한 덩어리.
class ParticipantSummary extends StatelessWidget {
  const ParticipantSummary({
    super.key,
    required this.names,
    this.avatarSize = 28,
    this.label,
    this.ringColor,
  });

  final List<String> names;
  final double avatarSize;
  final Color? ringColor;

  /// 얼굴 옆에 적을 말. 없으면 'N명 참여 중'.
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) {
      return Text('아직 아무도 없어요', style: context.texts.labelSmall);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarStack(names: names, size: avatarSize, ringColor: ringColor),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label ?? '${names.length}명 참여 중',
          style: context.texts.labelSmall,
        ),
      ],
    );
  }
}
