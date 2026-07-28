import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

/// 은근히 타오르는 불꽃.
///
/// 인기 표시라 시선을 한 번 끌어야 하지만, 작은 아이콘이라 크게 움직이면
/// 산만해진다. 크기를 조금씩 오르내리는 정도로 둔다.
///
/// 기기에서 애니메이션 줄이기를 켜면 멈춘 아이콘을 보여준다. 접근성 설정이기도
/// 하고, 무한 반복 애니메이션이 있으면 테스트의 pumpAndSettle 이 끝나지 않는다.
class FlameIcon extends StatefulWidget {
  const FlameIcon({super.key, required this.color, this.size = 15});

  final Color color;
  final double size;

  @override
  State<FlameIcon> createState() => _FlameIconState();
}

class _FlameIconState extends State<FlameIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _scale = Tween(
    begin: 1.0,
    end: 1.16,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      CupertinoIcons.flame_fill,
      size: widget.size,
      color: widget.color,
    );

    if (MediaQuery.disableAnimationsOf(context)) return icon;

    return ScaleTransition(scale: _scale, child: icon);
  }
}
