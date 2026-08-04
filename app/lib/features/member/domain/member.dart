import '../../../shared/domain/chapter.dart';

/// 사람 한 명.
///
/// 내 프로필과 남의 프로필을 한 타입으로 둔다. 둘을 나누면 '내가 보는 나'와
/// '남이 보는 나'가 어긋나기 시작하는데, 정작 같아야 하는 값이다.
///
/// 닉네임과 분야만 필수고 나머지는 비어 있을 수 있어서, 화면에서는 채워진
/// 것만 골라 보여준다.
class Member {
  const Member({
    required this.id,
    required this.nickname,
    required this.field,
    required this.chapter,
    required this.joinedAt,
    this.avatarUrl,
    this.bio,
    this.affiliation,
    this.stacks = const [],
    this.interests = const [],
    this.isStaff = false,
  });

  /// 사람을 가리키는 열쇠.
  ///
  /// 목업에서는 닉네임과 같은 값을 쓴다. 목업 글·모임이 이름 문자열로 이어져
  /// 있어서다. 서버가 붙으면 진짜 id 가 오고, 그때 닉네임을 바꿔도 차단이
  /// 풀리거나 글쓴이가 갈리는 일이 없어진다.
  final String id;

  final String nickname;

  /// 지금 하고 있는 일. '백엔드', '학생'처럼 자유롭게 적는다.
  final String field;

  final Chapter chapter;

  /// 가입한 날. '함께한 지 N일'을 재는 기준이다.
  final DateTime joinedAt;

  final String? avatarUrl;

  /// 자기소개. 없으면 그 자리를 비운다.
  final String? bio;

  /// 회사·학교. 밝히고 싶지 않을 수 있어 선택 항목이다.
  final String? affiliation;

  final List<String> stacks;
  final List<String> interests;

  /// 지부 운영진인지. 공지를 올리고 행사를 검토하는 계정이다.
  final bool isStaff;

  /// 고친 값으로 새 프로필을 만든다.
  ///
  /// 자기소개와 소속은 지울 수 있어야 해서 [String?] 로는 '안 바꿈'과 '비움'을
  /// 가릴 수 없다. 비우려면 빈 문자열을 넘긴다.
  Member copyWith({
    String? nickname,
    String? field,
    String? bio,
    String? affiliation,
    List<String>? stacks,
    List<String>? interests,
  }) {
    String? orNull(String? value) =>
        value == null || value.trim().isEmpty ? null : value.trim();

    return Member(
      id: id,
      nickname: nickname ?? this.nickname,
      field: field ?? this.field,
      chapter: chapter,
      joinedAt: joinedAt,
      avatarUrl: avatarUrl,
      bio: bio == null ? this.bio : orNull(bio),
      affiliation: affiliation == null ? this.affiliation : orNull(affiliation),
      stacks: stacks ?? this.stacks,
      interests: interests ?? this.interests,
      isStaff: isStaff,
    );
  }

  /// 가입한 지 며칠 됐는지. 오늘 가입했으면 1일째다.
  int daysSinceJoin(DateTime now) {
    final joined = DateTime(joinedAt.year, joinedAt.month, joinedAt.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(joined).inDays + 1;
  }
}
