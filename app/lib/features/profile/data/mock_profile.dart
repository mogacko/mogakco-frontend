import '../../../shared/domain/chapter.dart';
import '../domain/user_profile.dart';

/// 화면을 채우기 위한 임시 데이터.
///
/// 회원가입이 아직 UI 뿐이라 가입에서 넘어온 값을 받을 데가 없다. 로그인이
/// 붙으면 이 파일은 지운다.
abstract final class MockProfile {
  /// 닉네임.
  ///
  /// 목업 모임의 모임장, 목업 글의 작성자와 같은 이름을 쓴다. 그래야 '내가
  /// 연 모임', '내가 쓴 글'이 실제로 집계되어 숫자가 살아 있는 것처럼 보인다.
  static const nickname = 'evan';

  static UserProfile from(DateTime now, {Chapter? chapter}) {
    return UserProfile(
      nickname: nickname,
      field: '프론트엔드',
      chapter: chapter ?? Chapter.seoul,
      // 가입일을 박아두면 '함께한 지 N일'이 실행할 때마다 늘어난다.
      joinedAt: now.subtract(const Duration(days: 274)),
      bio: '카페에서 각자 코딩하는 자리를 좋아합니다. 요즘은 Flutter로 앱 만드는 중이에요.',
      affiliation: '오션스타',
      stacks: ['Flutter', 'Dart', 'TypeScript', 'React', 'Spring', 'AWS'],
      interests: ['모바일', 'UI·UX', '사이드 프로젝트'],
    );
  }
}
