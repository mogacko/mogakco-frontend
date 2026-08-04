/// 신고할 수 있는 것.
enum ReportTarget {
  post('글'),
  comment('댓글'),
  meetup('모각코'),
  event('행사'),
  member('사용자');

  const ReportTarget(this.label);

  final String label;
}

/// 신고 사유.
///
/// 직접 적게만 두면 대부분 비워 두거나 '그냥요'라고 적는다. 고르게 해야
/// 무엇이 문제인지가 집계되고, 운영진이 같은 유형을 묶어 볼 수 있다.
enum ReportReason {
  spam('스팸·광고', '홍보 글이거나 같은 내용을 반복해서 올려요'),
  abuse('욕설·비방', '특정인을 지목해 헐뜯거나 모욕해요'),
  sexual('음란물', '성적인 내용이나 이미지가 있어요'),
  fraud('사기·거래', '돈을 요구하거나 거래를 유도해요'),
  impersonation('사칭', '다른 사람이나 운영진인 척해요'),
  other('기타', '위에 없는 이유예요');

  const ReportReason(this.label, this.description);

  final String label;
  final String description;

  /// 직접 적어야 하는 사유인지. 기타만 받는다.
  bool get needsNote => this == ReportReason.other;
}

/// 접수된 신고 한 건.
class Report {
  const Report({
    required this.target,
    required this.targetId,
    required this.reason,
    required this.createdAt,
    this.note,
  });

  final ReportTarget target;
  final String targetId;
  final ReportReason reason;

  /// 직접 적은 말. 기타일 때만 채워진다.
  final String? note;

  final DateTime createdAt;

  /// 같은 것을 두 번 신고했는지 가리는 열쇠.
  String get key => '${target.name}:$targetId';
}
