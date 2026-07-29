import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 기준 시각.
///
/// '오늘/내일', '3시간 전', 'D-2'를 재는 잣대다. 모임·글·행사가 모두 같은
/// 시각을 봐야 한 화면 안에서 계산이 어긋나지 않는다. `DateTime.now()`를
/// 화면 곳곳에 흩지 않고 여기 한 곳에 둔다.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());
