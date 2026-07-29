import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/now_provider.dart';
import '../../community/presentation/post_provider.dart';
import '../../event/presentation/event_provider.dart';
import '../../meetup/presentation/meetup_provider.dart';
import '../data/mock_profile.dart';
import '../domain/user_profile.dart';

final profileProvider = Provider<UserProfile>((ref) {
  final now = ref.watch(nowProvider);
  return MockProfile.from(now);
});

/// 내 활동 요약.
///
/// 숫자를 목업으로 박아두지 않고 실제 상태에서 센다. 홈에서 모임 하나를
/// 신청하면 이 값이 곧바로 올라가야, 프로필이 박제된 소개 화면이 아니라
/// 내 기록으로 읽힌다.
typedef ProfileStats = ({int joinedSessions, int appliedEvents, int posts});

final profileStatsProvider = Provider<ProfileStats>((ref) {
  final nickname = ref.watch(profileProvider).nickname;

  // 지역을 걸러내지 않는다. 서울에 갔다가 부산으로 돌아와도 내가 신청한
  // 자리는 그대로 내 것이다.
  final joinedSessions = ref
      .watch(meetupListProvider)
      .fold<int>(
        0,
        (sum, meetup) =>
            sum + meetup.sessions.where((session) => session.isJoined).length,
      );

  final appliedEvents = ref
      .watch(eventListProvider)
      .where((event) => event.isApplied)
      .length;

  final posts = ref
      .watch(postFeedProvider)
      .where((post) => post.author == nickname)
      .length;

  return (
    joinedSessions: joinedSessions,
    appliedEvents: appliedEvents,
    posts: posts,
  );
});

/// 모임 소식·마케팅 정보 수신 동의.
///
/// 가입할 때 고른 값이 들어올 자리다. 선택 약관이라 언제든 바꿀 수 있어야
/// 해서 프로필에서도 끄고 켠다.
class MarketingOptIn extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final marketingOptInProvider = NotifierProvider<MarketingOptIn, bool>(
  MarketingOptIn.new,
);
