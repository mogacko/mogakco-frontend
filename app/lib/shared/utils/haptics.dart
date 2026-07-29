import 'package:flutter/services.dart';

/// 손끝으로 주는 확인.
///
/// 절제형에서 가장 값싼 마감이다. 화면에 아무것도 더하지 않으면서 방금 누른
/// 것이 실제로 먹혔다는 걸 알려준다. 네이티브에서는 비용이 사실상 없다.
/// 웹에서는 채널을 받는 쪽이 없어 조용히 넘어간다.
///
/// 함부로 울리면 금세 성가셔지므로 자리를 좁게 잡는다. 화면 이동이나 스크롤,
/// 탭 전환에는 쓰지 않는다. iOS 기본 앱들도 거기서는 울리지 않는다.
abstract final class Haptics {
  /// 상태가 실제로 바뀌는 결정. 참여·신청·취소처럼 되돌리려면 한 번 더
  /// 손이 가는 일에만 쓴다.
  static void decide() => HapticFeedback.mediumImpact();

  /// 좋아요처럼 가볍게 켜고 끄는 반응.
  ///
  /// 결정보다 한 단계 약하다. 같은 세기로 울리면 무게가 같아 보인다.
  static void toggle() => HapticFeedback.selectionClick();
}
