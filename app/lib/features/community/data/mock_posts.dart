import '../../../shared/domain/chapter.dart';
import '../domain/post.dart';

/// 화면을 채우기 위한 임시 데이터.
///
/// 서버 연동 전까지만 쓴다. 실제 데이터가 붙으면 이 파일은 지운다.
abstract final class MockPosts {
  /// [now]를 기준으로 최근 글들을 만든다.
  ///
  /// 고정 날짜를 박아두면 하루만 지나도 '3일 전'이 '한 달 전'이 되어 목록이
  /// 죽은 게시판처럼 보인다. 작성 시각을 지금으로부터 상대로 잡는다.
  static List<Post> from(DateTime now) {
    DateTime ago(Duration duration) => now.subtract(duration);

    return [
      Post(
        id: 'busan-p1',
        chapter: Chapter.busan,
        category: PostCategory.question,
        title: 'Flutter 웹에서 안전영역(safe area)이 0으로 잡히는데 정상인가요?',
        excerpt:
            'PWA로 홈 화면에 추가하고 보니 MediaQuery.padding.bottom이 계속 0이더라고요. '
            '네이티브에서는 34가 잘 들어오는데 웹만 그렇습니다. 혹시 겪어보신 분 계실까요?',
        author: '재현',
        createdAt: ago(const Duration(minutes: 24)),
        likeCount: 12,
        commentCount: 8,
      ),
      Post(
        id: 'busan-p2',
        chapter: Chapter.busan,
        category: PostCategory.retrospective,
        title: '3개월 만에 첫 사이드 프로젝트 배포했습니다',
        excerpt:
            '모각코 나오기 시작한 게 3월이었는데 그때 시작한 걸 드디어 올렸어요. '
            '혼자 했으면 두 번은 접었을 것 같습니다. 매주 나와서 같이 앉아주신 분들 덕분이에요.',
        author: '수민',
        createdAt: ago(const Duration(hours: 3)),
        likeCount: 47,
        commentCount: 15,
        isLiked: true,
      ),
      Post(
        id: 'busan-p3',
        chapter: Chapter.busan,
        category: PostCategory.recruit,
        title: '토요일 알고리즘 스터디 같이 하실 분 (3명)',
        excerpt:
            '매주 토요일 오전에 모각코 끝나고 두 시간 정도 백준 골드 난이도로 같이 풀어요. '
            '언어는 상관없고 풀이 공유만 할 수 있으면 됩니다.',
        author: 'evan',
        createdAt: ago(const Duration(hours: 9)),
        likeCount: 9,
        commentCount: 21,
      ),
      Post(
        id: 'busan-p4',
        chapter: Chapter.busan,
        category: PostCategory.free,
        title: '온천장 근처 콘센트 많은 카페 추천받아요',
        excerpt:
            '모모스는 자리 잡기가 너무 어려워서요. 노트북 오래 써도 눈치 안 보이는 곳 있을까요?',
        author: '도윤',
        createdAt: ago(const Duration(days: 1, hours: 2)),
        likeCount: 6,
        commentCount: 11,
      ),
      Post(
        id: 'busan-p5',
        chapter: Chapter.busan,
        category: PostCategory.question,
        title: 'Spring Boot 3.x에서 QueryDSL 설정이 자꾸 깨집니다',
        excerpt:
            'Gradle 8로 올리고 나서 Q클래스가 생성이 안 되네요. '
            'annotationProcessor 경로 문제인 것 같은데 해결하신 분 있나요?',
        author: '지훈',
        createdAt: ago(const Duration(days: 2, hours: 5)),
        likeCount: 14,
        commentCount: 6,
      ),
      Post(
        id: 'busan-p6',
        chapter: Chapter.busan,
        category: PostCategory.free,
        title: '다들 모각코 오실 때 장비 뭐 챙기시나요',
        excerpt: '노트북 거치대까지 들고 다니려니 가방이 너무 무거워서요. 다들 어떻게 하시는지 궁금합니다.',
        author: '민서',
        createdAt: ago(const Duration(days: 4)),
        likeCount: 3,
        commentCount: 9,
      ),
      Post(
        id: 'seoul-p1',
        chapter: Chapter.seoul,
        category: PostCategory.retrospective,
        title: '이직 준비 6개월 회고 — 결국 붙었습니다',
        excerpt:
            '작년 이맘때 성수 모각코에서 처음 이력서 썼던 게 기억나네요. '
            '준비하면서 정리한 것들 공유드립니다. 길지만 도움 되셨으면 좋겠어요.',
        author: '하늘',
        createdAt: ago(const Duration(hours: 6)),
        likeCount: 82,
        commentCount: 34,
      ),
      Post(
        id: 'seoul-p2',
        chapter: Chapter.seoul,
        category: PostCategory.question,
        title: 'React Query v5 마이그레이션 하신 분 계신가요',
        excerpt:
            'isLoading이 isPending으로 바뀌면서 손댈 곳이 생각보다 많네요. '
            '한 번에 올리셨는지 아니면 나눠서 하셨는지 궁금합니다.',
        author: '지우',
        createdAt: ago(const Duration(days: 1, hours: 8)),
        likeCount: 18,
        commentCount: 12,
      ),
      Post(
        id: 'seoul-p3',
        chapter: Chapter.seoul,
        category: PostCategory.recruit,
        title: '사이드 프로젝트 디자이너 한 분 찾습니다',
        excerpt:
            '개발 3명이서 두 달째 만들고 있는데 화면이 영 안 예뻐서요. '
            '가볍게 참여하실 분 계시면 댓글 남겨주세요.',
        author: '민준',
        createdAt: ago(const Duration(days: 3, hours: 4)),
        likeCount: 21,
        commentCount: 17,
      ),
      Post(
        id: 'seoul-p4',
        chapter: Chapter.seoul,
        category: PostCategory.free,
        title: '합정 스터디홀 새로 생긴 곳 다녀왔습니다',
        excerpt: '자리마다 콘센트 있고 조용해서 좋더라고요. 다만 주말은 예약 필수인 것 같습니다.',
        author: '서연',
        createdAt: ago(const Duration(days: 5, hours: 6)),
        likeCount: 11,
        commentCount: 4,
      ),
    ];
  }
}
