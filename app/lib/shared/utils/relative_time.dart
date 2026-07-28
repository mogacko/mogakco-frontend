/// 지난 시간을 사람이 읽는 말로 바꾼다.
///
/// '몇 시 몇 분'보다 '얼마나 됐는지'가 글의 신선도를 가늠하기 쉽다.
/// 하루가 넘어가면 날짜가 더 명확해서 그때부터는 날짜로 적는다.
String relativeTime(DateTime time, DateTime now) {
  final gap = now.difference(time);

  if (gap.isNegative) return '방금';
  if (gap.inMinutes < 1) return '방금';
  if (gap.inHours < 1) return '${gap.inMinutes}분 전';
  if (gap.inHours < 24) return '${gap.inHours}시간 전';
  if (gap.inDays < 7) return '${gap.inDays}일 전';

  return '${time.month}월 ${time.day}일';
}
