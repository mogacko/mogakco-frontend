/// 프로필에서 고르는 태그 목록.
///
/// 자유 입력 대신 정해진 목록에서 고르게 한다. 표기가 흔들리지 않아야
/// 나중에 '같은 스택 쓰는 사람' 같은 필터를 붙일 수 있다.
abstract final class ProfileOptions {
  /// 사용 기술. 언어 → 프레임워크 → 인프라 순으로 둔다.
  static const stacks = <String>[
    'Java',
    'Spring',
    'Kotlin',
    'Python',
    'FastAPI',
    'Django',
    'JavaScript',
    'TypeScript',
    'React',
    'Next.js',
    'Vue',
    'Node.js',
    'Flutter',
    'Dart',
    'Swift',
    'Go',
    'Rust',
    'C/C++',
    'C#',
    'PHP',
    'SQL',
    'AWS',
    'Docker',
    'Kubernetes',
  ];

  /// 지금 하고 있는 일. 하나만 고르되 목록에 없으면 직접 적을 수 있다.
  ///
  /// 모각코는 카페에서 각자 작업하는 자리지 개발자 전용이 아니다.
  /// 개발 직군을 앞에 두되 그 외 분야도 함께 담는다.
  static const fields = <String>[
    '백엔드',
    '프론트엔드',
    '풀스택',
    '모바일',
    '데이터·AI',
    'DevOps·인프라',
    '보안',
    '게임',
    '임베디드',
    '기획·PM',
    '디자인',
    '마케팅',
    '창업',
    '연구·논문',
    '어학·자격증',
    '글쓰기',
    '학생',
    '취업 준비',
  ];

  /// 배우고 싶거나 관심 있는 것. 여러 개 고를 수 있다.
  ///
  /// [fields]와 항목이 겹치는 건 의도한 것이다.
  /// 백엔드를 하면서 프론트엔드를 배우고 싶은 경우가 흔하다.
  static const interests = <String>[
    '백엔드',
    '프론트엔드',
    '모바일',
    '데이터·AI',
    'DevOps',
    '클라우드',
    '보안',
    '게임',
    '블록체인',
    '알고리즘',
    'UI·UX',
    '사이드 프로젝트',
  ];
}
