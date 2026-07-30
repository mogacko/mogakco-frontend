import '../domain/comment.dart';

/// 화면을 채우기 위한 임시 데이터.
///
/// 서버 연동 전까지만 쓴다. 실제 데이터가 붙으면 이 파일은 지운다.
///
/// 글마다 댓글 수가 다르다. 질문 게시판은 답이 여러 개 붙고, 공지는 거의
/// 안 붙는다. 목록에 찍히는 댓글 수는 이 목록을 세어 나오므로 따로 맞출 값이
/// 없다.
abstract final class MockComments {
  static List<Comment> from(DateTime now) {
    DateTime ago(Duration duration) => now.subtract(duration);

    var seq = 0;
    Comment c(
      String postId,
      String author,
      String body,
      Duration since, {
      bool isMine = false,
    }) {
      seq++;
      return Comment(
        id: 'c$seq',
        postId: postId,
        author: author,
        body: body,
        createdAt: ago(since),
        isMine: isMine,
      );
    }

    return [
      // 공지 — 반응이 적다
      c('busan-n1', '수민', '알려주셔서 감사합니다. 오리진 2층 자리 넓던데 좋네요.', const Duration(hours: 4)),
      c('busan-n1', '도윤', '공사 끝나면 다시 돌아가는 건가요?', const Duration(hours: 2)),

      // 질문 — 답이 여러 개
      c(
        'busan-q1',
        '수민',
        'Flutter Web 엔진이 safe-area-inset 을 아예 안 읽습니다. '
            'ViewPadding 이 zero 로 고정돼 있어요.',
        const Duration(minutes: 18),
      ),
      c(
        'busan-q1',
        'evan',
        '맞습니다. CSS 에서 body padding 으로 빼주는 수밖에 없어요. '
            'viewport-fit=cover 를 같이 안 쓰면 env() 도 0 이 나옵니다.',
        const Duration(minutes: 12),
        isMine: true,
      ),
      c('busan-q1', '지훈', '저도 이거 때문에 반나절 날렸네요.', const Duration(minutes: 6)),
      c(
        'busan-q2',
        'evan',
        'Gradle 8 부터 annotationProcessor 출력 경로가 바뀌었습니다. '
            'build/generated/sources/annotationProcessor 쪽을 소스셋에 추가해보세요.',
        const Duration(days: 2, hours: 3),
        isMine: true,
      ),
      c('busan-q2', '민서', '저는 kapt 걷어내고 annotationProcessor 로만 갔더니 됐어요.', const Duration(days: 1)),

      // 이야기 — 축하와 잡담
      c('busan-t1', 'evan', '축하드려요. 3월에 뵀을 때 기획만 있던 게 벌써 배포라니.', const Duration(hours: 2), isMine: true),
      c('busan-t1', '재현', '링크 공유해주실 수 있나요? 궁금합니다.', const Duration(hours: 2)),
      c('busan-t1', '도윤', '저도 이번 달에 하나 끝내보려고요. 자극받았습니다.', const Duration(hours: 1)),
      c('busan-t1', '민서', '고생하셨어요!', const Duration(minutes: 40)),
      c('busan-t2', '민서', '언어 상관없다고 하셔서 신청합니다. 파이썬으로 풀어요.', const Duration(hours: 7)),
      c('busan-t2', '지훈', '골드면 저는 좀 벅찰까요? 실버 후반쯤 됩니다.', const Duration(hours: 5)),
      c('busan-t2', 'evan', '실버여도 괜찮아요. 같이 풀고 풀이만 나누면 됩니다.', const Duration(hours: 4), isMine: true),
      c('busan-t3', '수민', '온천장이면 스테이지원도 괜찮아요. 자리마다 콘센트 있습니다.', const Duration(days: 1)),
      c('busan-t3', '재현', '평일 오전엔 모모스도 한산해요.', const Duration(hours: 20)),
      c('busan-t4', '도윤', '저는 거치대 대신 노트북 받침 접이식 쓰는데 훨씬 가벼워요.', const Duration(days: 3)),
      c('busan-t4', '수민', '멀티탭은 하나 챙기시면 좋습니다. 콘센트 하나로 둘이 씁니다.', const Duration(days: 3)),

      // 서울
      c('seoul-n1', '지우', '수요일 저녁 좋네요. 퇴근하고 바로 갈 수 있습니다.', const Duration(hours: 20)),
      c('seoul-q1', '하늘', 'isPending 은 이름만 바뀐 거라 일괄 치환으로 됐어요. '
          'status 쓰던 곳이 더 손이 갑니다.', const Duration(days: 1, hours: 4)),
      c('seoul-q1', '서연', '저는 페이지 단위로 나눠서 두 주에 걸쳐 올렸습니다.', const Duration(hours: 22)),
      c('seoul-t1', '민준', '고생하셨습니다. 정리해주신 것 잘 봤어요.', const Duration(hours: 5)),
      c('seoul-t1', '지우', '이력서 부분만 따로 여쭤봐도 될까요?', const Duration(hours: 3)),
      c('seoul-t1', '서연', '축하드려요!', const Duration(hours: 1)),
      c('seoul-t2', '서연', '포트폴리오 보내드릴게요. 어떤 서비스인지 궁금합니다.', const Duration(days: 3)),
      c('seoul-t3', '지우', '예약이 필수면 미리 알아야겠네요. 감사합니다.', const Duration(days: 5)),
    ];
  }
}
