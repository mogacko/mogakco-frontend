import '../../../shared/domain/chapter.dart';
import '../domain/member.dart';

/// 목업 사람들.
///
/// 목업 글의 글쓴이, 모임의 모임장·참여자가 모두 여기 있는 사람이어야 한다.
/// 없는 이름이 섞이면 참여자를 눌렀을 때 '없는 사람'이 뜬다.
///
/// 서버가 붙으면 지운다.
abstract final class MockMembers {
  /// 지부 운영진 계정. 공지를 올리는 사람이다.
  static const staffNickname = '운영진';

  static List<Member> from(DateTime now) {
    DateTime joined(int days) => now.subtract(Duration(days: days));

    Member m(
      String nickname,
      Chapter chapter,
      String field, {
      String? affiliation,
      String? bio,
      List<String> stacks = const [],
      List<String> interests = const [],
      int days = 120,
      bool isStaff = false,
    }) {
      return Member(
        // 목업에서는 닉네임이 곧 열쇠다. 글·모임이 이름으로 이어져 있다.
        id: nickname,
        nickname: nickname,
        chapter: chapter,
        field: field,
        affiliation: affiliation,
        bio: bio,
        stacks: stacks,
        interests: interests,
        joinedAt: joined(days),
        isStaff: isStaff,
      );
    }

    return [
      // ── 부산 ────────────────────────────────────────────────
      m(
        '재현',
        Chapter.busan,
        '백엔드',
        affiliation: '토스',
        bio: '주말마다 모모스에서 각자 코딩합니다. 처음 오시는 분 있으면 반가워요.',
        stacks: ['Java', 'Spring', 'PostgreSQL', 'AWS'],
        interests: ['사이드 프로젝트', '스터디'],
        days: 612,
      ),
      m(
        '수민',
        Chapter.busan,
        '프론트엔드',
        affiliation: '프리랜서',
        bio: '3개월 만에 첫 사이드 프로젝트를 배포했습니다.',
        stacks: ['TypeScript', 'React', 'Next.js'],
        interests: ['사이드 프로젝트', 'UI·UX'],
        days: 340,
      ),
      m(
        '도윤',
        Chapter.busan,
        '학생',
        affiliation: '부산대학교',
        bio: '알고리즘 공부 중입니다. 골드 문제 같이 푸실 분 찾아요.',
        stacks: ['C++', 'Python'],
        interests: ['알고리즘', '취업 준비'],
        days: 96,
      ),
      m(
        '민서',
        Chapter.busan,
        '데이터',
        affiliation: '부산은행',
        stacks: ['Python', 'SQL', 'Airflow'],
        interests: ['데이터 분석'],
        days: 210,
      ),
      m(
        '지훈',
        Chapter.busan,
        '학생',
        bio: '실버 후반에서 골드로 넘어가는 중입니다.',
        stacks: ['Python'],
        interests: ['알고리즘'],
        days: 62,
      ),
      m(
        '서연',
        Chapter.busan,
        '디자이너',
        affiliation: '오션스타',
        bio: '개발자분들 옆에서 같이 작업하면 물어보기 좋아서 나옵니다.',
        stacks: ['Figma'],
        interests: ['UI·UX', '사이드 프로젝트'],
        days: 155,
      ),
      m(
        '태오',
        Chapter.busan,
        '안드로이드',
        stacks: ['Kotlin', 'Compose'],
        interests: ['모바일'],
        days: 88,
      ),
      m(
        '나윤',
        Chapter.busan,
        'iOS',
        affiliation: '카카오모빌리티',
        stacks: ['Swift', 'SwiftUI'],
        interests: ['모바일'],
        days: 274,
      ),
      m(
        '준서',
        Chapter.busan,
        '인프라',
        stacks: ['Kubernetes', 'Terraform', 'AWS'],
        interests: ['인프라'],
        days: 401,
      ),
      m(
        '하람',
        Chapter.busan,
        '학생',
        affiliation: '동아대학교',
        stacks: ['JavaScript'],
        interests: ['취업 준비'],
        days: 41,
      ),

      // ── 서울 ────────────────────────────────────────────────
      m(
        '하늘',
        Chapter.seoul,
        '백엔드',
        affiliation: '당근',
        bio: '강남에서 주말 오전에 모입니다. 조용한 편이에요.',
        stacks: ['Go', 'Kubernetes', 'PostgreSQL'],
        interests: ['스터디'],
        days: 520,
      ),
      m(
        '지우',
        Chapter.seoul,
        '프론트엔드',
        affiliation: '무신사',
        stacks: ['TypeScript', 'React', 'Storybook'],
        interests: ['UI·UX'],
        days: 300,
      ),
      m(
        '민준',
        Chapter.seoul,
        '머신러닝',
        affiliation: '네이버',
        bio: '성수에서 저녁에 모입니다. 논문 같이 읽을 분 환영해요.',
        stacks: ['Python', 'PyTorch'],
        interests: ['AI', '스터디'],
        days: 455,
      ),
      m(
        '예린',
        Chapter.seoul,
        '기획',
        affiliation: '토스',
        stacks: ['Figma', 'Amplitude'],
        interests: ['사이드 프로젝트'],
        days: 180,
      ),
      m(
        '시우',
        Chapter.seoul,
        '학생',
        affiliation: '서울대학교',
        stacks: ['C++'],
        interests: ['알고리즘', '취업 준비'],
        days: 73,
      ),
      m(
        '유진',
        Chapter.seoul,
        '안드로이드',
        stacks: ['Kotlin', 'Compose'],
        interests: ['모바일'],
        days: 128,
      ),
      m(
        '다인',
        Chapter.seoul,
        '데브옵스',
        affiliation: '쿠팡',
        stacks: ['Terraform', 'AWS', 'Go'],
        interests: ['인프라'],
        days: 366,
      ),
      m(
        '건우',
        Chapter.seoul,
        '백엔드',
        stacks: ['Node.js', 'NestJS'],
        interests: ['사이드 프로젝트'],
        days: 59,
      ),

      // ── 운영진 ──────────────────────────────────────────────
      // 지부마다 한 계정씩 쓴다. 공지 글쓴이가 이 이름이라, 눌렀을 때
      // 없는 사람이 되지 않도록 둔다.
      m(
        staffNickname,
        Chapter.busan,
        '운영',
        bio: '부산 모각코를 챙깁니다. 문의는 여기로 주세요.',
        days: 900,
        isStaff: true,
      ),
    ];
  }

  /// 지부의 사람들. 운영진은 뺀다 — 참여자로 세울 자리가 아니다.
  static List<Member> of(DateTime now, Chapter chapter) => from(now)
      .where((member) => member.chapter == chapter && !member.isStaff)
      .toList();
}
