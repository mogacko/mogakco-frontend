import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/now_provider.dart';
import '../domain/report.dart';

/// 내가 낸 신고들.
///
/// 서버로 보내고 나면 앱이 들고 있을 이유가 없어 보이지만, 두 가지가 필요하다.
/// 같은 것을 두 번 신고하지 않게 막는 일과, 신고한 것을 내 화면에서 바로
/// 가리는 일이다. 뒤엣것이 없으면 신고하고도 계속 보여서 신고가 소용없어
/// 보인다.
class Reports extends Notifier<List<Report>> {
  @override
  List<Report> build() => const [];

  void add({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    String? note,
  }) {
    if (has(target, targetId)) return;

    state = [
      ...state,
      Report(
        target: target,
        targetId: targetId,
        reason: reason,
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
        createdAt: ref.read(nowProvider),
      ),
    ];
  }

  bool has(ReportTarget target, String targetId) =>
      state.any((report) => report.key == '${target.name}:$targetId');
}

final reportsProvider = NotifierProvider<Reports, List<Report>>(Reports.new);

/// 이미 신고한 것들의 열쇠. 목록에서 걸러낼 때 쓴다.
final reportedKeysProvider = Provider<Set<String>>((ref) {
  return ref.watch(reportsProvider).map((report) => report.key).toSet();
});

/// 내가 차단한 사람들.
///
/// 차단은 양방향이다. 그 사람 글·댓글이 내 목록에서 사라지고, 그 사람은 내
/// 프로필을 볼 수 없다. 프로필만 막으면 차단한 이유 — 대개 그 사람 글이
/// 불편해서다 — 가 그대로 남는다.
///
/// 서버가 붙으면 계정에 저장된다. 지금은 앱을 다시 켜면 풀린다.
class BlockedMembers extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void block(String memberId) => state = {...state, memberId};

  void unblock(String memberId) =>
      state = {...state}..removeWhere((id) => id == memberId);

  bool has(String memberId) => state.contains(memberId);
}

final blockedProvider = NotifierProvider<BlockedMembers, Set<String>>(
  BlockedMembers.new,
);
