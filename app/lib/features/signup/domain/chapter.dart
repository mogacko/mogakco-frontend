/// 활동 지역(챕터).
///
/// 로고는 10개 지역 모두 준비돼 있지만 실제로 운영 중인 곳만 [isOpen]이 true다.
/// 새 지역이 열리면 해당 항목의 [isOpen]만 true로 바꾸면 가입 화면에 나타난다.
enum Chapter {
  seoul('서울', isOpen: true),
  busan('부산', isOpen: true),
  gyeonggi('경기'),
  incheon('인천'),
  daejeon('대전'),
  daegu('대구'),
  gwangju('광주'),
  ulsan('울산'),
  gangwon('강원'),
  jeju('제주');

  const Chapter(this.label, {this.isOpen = false});

  /// 화면에 보이는 지역명
  final String label;

  /// 운영 중인 지역인지
  final bool isOpen;

  /// 워드마크 에셋 경로
  String get logoAsset => 'assets/logos/chapters/mogakco-$name.svg';

  /// 가입 시 고를 수 있는 지역
  static List<Chapter> get open =>
      values.where((chapter) => chapter.isOpen).toList();
}
