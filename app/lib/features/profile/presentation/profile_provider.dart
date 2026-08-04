import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/now_provider.dart';
import '../../auth/presentation/session_provider.dart';
import '../../comment/presentation/comment_provider.dart';
import '../../community/presentation/post_provider.dart';
import '../../event/presentation/event_provider.dart';
import '../../meetup/presentation/meetup_provider.dart';
import '../data/mock_profile.dart';
import '../../member/domain/member.dart';

/// 내 프로필.
///
/// 고칠 수 있어야 해서 파생 값이 아니라 상태로 둔다. 로그아웃하면 세션이
/// 바뀌면서 다시 만들어져 고친 내용도 함께 사라진다 — 다음 사람이 이 기기에서
/// 로그인했을 때 앞사람의 프로필이 남아 있으면 안 된다.
class ProfileState extends Notifier<Member> {
  @override
  Member build() {
    final now = ref.watch(nowProvider);
    // 지역은 목업이 아니라 로그인한 계정에서 온다. 둘이 어긋나면 내 정보에
    // 적힌 지역과 실제로 보고 있는 지부가 달라진다.
    //
    // 지역만 지켜본다. 세션 전체를 보면 [save] 가 세션 닉네임을 고치는 순간
    // 이 build 가 다시 돌아 방금 저장한 프로필을 목업으로 되돌린다.
    final chapter = ref.watch(sessionProvider.select((s) => s?.chapter));
    return MockProfile.from(now, chapter: chapter);
  }

  /// 고친 프로필을 저장한다.
  ///
  /// 닉네임이 바뀌면 내가 쓴 글·댓글·연 모임의 이름까지 함께 간다. 서버라면
  /// 사용자 id 로 이어져 있어 저절로 따라오는 자리다. 목업은 이름 문자열이
  /// 곧 사람이라, 여기서 맞춰주지 않으면 닉네임을 고치는 순간 내 글이 남의
  /// 글이 되고 작성글 수가 0으로 떨어진다.
  void save(Member profile) {
    final before = state.nickname;
    state = profile;

    if (profile.nickname == before) return;

    ref.read(sessionProvider.notifier).rename(profile.nickname);
    ref.read(postFeedProvider.notifier).renameAuthor(before, profile.nickname);
    ref.read(meetupListProvider.notifier).renameHost(before, profile.nickname);
    ref.read(commentListProvider.notifier).renameAuthor(profile.nickname);
  }
}

final profileProvider = NotifierProvider<ProfileState, Member>(
  ProfileState.new,
);

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
