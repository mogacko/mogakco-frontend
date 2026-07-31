import '../../../shared/domain/chapter.dart';

/// 행사의 종류.
enum EventKind {
  seminar('세미나'),
  hackathon('해커톤'),
  networking('네트워킹'),
  retrospective('회고'),
  // 위 넷에 들어가지 않는 자리. 분류를 억지로 맞추다 이름이 헐거워지는 것보다
  // 여기로 보내는 편이 낫다.
  other('기타');

  const EventKind(this.label);

  final String label;
}

/// 지부가 여는 공식 행사.
///
/// 모각코 모임과 다르다. 모임은 누구나 카페 자리를 잡아 열고 그 주에만
/// 열리지만, 행사는 운영진이 공간을 빌려 하루짜리로 열고 신청 마감일이
/// 따로 있다. 참가비가 붙기도 한다.
///
/// 그래서 참여를 '토글'이 아니라 '신청'으로 다룬다. 마감이 지나면 자리가
/// 남아 있어도 더 받지 않는다.
class Event {
  const Event({
    required this.id,
    required this.chapter,
    required this.kind,
    required this.title,
    required this.summary,
    required this.venue,
    required this.startsAt,
    required this.endsAt,
    required this.applyBy,
    required this.capacity,
    required this.applicantCount,
    this.fee = 0,
    this.posterUrl,
    this.isApplied = false,
  });

  final String id;
  final Chapter chapter;
  final EventKind kind;

  final String title;

  /// 무엇을 하는 자리인지 한두 줄
  final String summary;

  /// 빌린 공간의 이름
  final String venue;

  final DateTime startsAt;
  final DateTime endsAt;

  /// 신청을 받는 마지막 시각.
  ///
  /// 자리 준비와 다과 수량을 미리 잡아야 해서 행사 당일보다 앞선다.
  final DateTime applyBy;

  final int capacity;
  final int applicantCount;

  /// 참가비. 0이면 무료.
  final int fee;

  /// 홍보 포스터. 없는 행사가 흔하다.
  ///
  /// 지부가 매번 포스터를 만들지는 않는다. 없을 때 자리가 비지 않도록
  /// 화면에서는 날짜 칸으로 대신한다.
  final String? posterUrl;

  /// 내가 신청했는지
  final bool isApplied;

  bool get isFree => fee == 0;
  bool get isFull => applicantCount >= capacity;
  int get remaining => (capacity - applicantCount).clamp(0, capacity);

  /// 신청 마감까지 남은 날. 오늘 마감이면 0, 지났으면 음수.
  ///
  /// 시:분을 떼고 날짜만 견준다. 오늘 밤 마감을 'D-1'로 세지 않기 위해서다.
  int daysToApplyBy(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(applyBy.year, applyBy.month, applyBy.day);
    return due.difference(today).inDays;
  }

  /// 신청이 닫혔는지.
  ///
  /// 마감 시각이 지났거나 자리가 다 찼거나 행사가 이미 시작했으면 닫힌다.
  bool isClosed(DateTime now) =>
      now.isAfter(applyBy) || isFull || now.isAfter(startsAt);

  /// 마감이 코앞인지. 서두르라는 표시를 붙일 기준이다.
  bool isUrgent(DateTime now) {
    final left = daysToApplyBy(now);
    return left >= 0 && left <= 3;
  }

  /// 'D-3', 'D-DAY', '마감'
  String ddayLabel(DateTime now) {
    if (now.isAfter(applyBy)) return '마감';
    return switch (daysToApplyBy(now)) {
      0 => 'D-DAY',
      final left => 'D-$left',
    };
  }

  /// 요일 한 글자
  String get weekdayLabel =>
      const ['월', '화', '수', '목', '금', '토', '일'][startsAt.weekday - 1];

  /// '8월 12일 (토)'. 확인 시트처럼 자리가 넉넉한 곳에 쓴다.
  String get dateLabel =>
      '${startsAt.month}월 ${startsAt.day}일 ($weekdayLabel)';

  /// '8/12 (토)'. 종류·마감과 한 줄에 놓일 때 쓴다.
  String get shortDateLabel =>
      '${startsAt.month}/${startsAt.day} ($weekdayLabel)';

  /// '14:00 - 18:00'
  String get timeRangeLabel => '${_hhmm(startsAt)} - ${_hhmm(endsAt)}';

  /// '무료' 또는 '15,000원'
  String get feeLabel => isFree ? '무료' : '${_thousands(fee)}원';

  Event apply() {
    if (isApplied) return this;
    return copyWith(isApplied: true, applicantCount: applicantCount + 1);
  }

  Event cancel() {
    if (!isApplied) return this;
    return copyWith(isApplied: false, applicantCount: applicantCount - 1);
  }

  Event copyWith({bool? isApplied, int? applicantCount}) {
    return Event(
      id: id,
      chapter: chapter,
      kind: kind,
      title: title,
      summary: summary,
      venue: venue,
      startsAt: startsAt,
      endsAt: endsAt,
      applyBy: applyBy,
      capacity: capacity,
      applicantCount: applicantCount ?? this.applicantCount,
      fee: fee,
      posterUrl: posterUrl,
      isApplied: isApplied ?? this.isApplied,
    );
  }

  static String _hhmm(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  /// 세 자리마다 쉼표. 금액은 쉼표가 없으면 자릿수를 세어 읽어야 한다.
  static String _thousands(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
