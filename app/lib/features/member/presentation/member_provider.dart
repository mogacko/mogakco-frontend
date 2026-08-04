import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/now_provider.dart';
import '../../auth/presentation/session_provider.dart';
import '../../profile/presentation/profile_provider.dart';
import '../data/mock_members.dart';
import '../domain/member.dart';

/// 사람 한 명 찾기.
///
/// 나를 찾으면 목업이 아니라 내 프로필을 준다. 참여자 목록에서 나를 눌렀는데
/// 프로필 수정에서 고친 내용이 안 보이면 둘이 다른 사람처럼 읽힌다.
///
/// 못 찾으면 null. 서버가 붙기 전에는 목업에 없는 이름이 섞일 수 있고,
/// 붙은 뒤에는 탈퇴한 사람이 그렇다.
final memberProvider = Provider.family<Member?, String>((ref, id) {
  final me = ref.watch(profileProvider);
  if (id == me.id || id == me.nickname) return me;

  final now = ref.watch(nowProvider);
  for (final member in MockMembers.from(now)) {
    if (member.id == id) return member;
  }
  return null;
});

/// 지금 로그인한 사람의 id.
///
/// 목업에서는 닉네임이 곧 id 다. 참여자 목록에서 '나'를 가리기 위해 쓴다.
final myIdProvider = Provider<String>((ref) {
  return ref.watch(sessionProvider)?.nickname ?? ref.watch(profileProvider).id;
});
