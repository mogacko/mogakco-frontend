import '../../../shared/domain/chapter.dart';

/// 로그인한 사람.
///
/// 서버가 붙기 전이라 토큰도 만료도 없다. 지금 있는 건 '누가 어느 지역으로
/// 들어와 있는가' 하나뿐이고, 그것만으로도 화면이 갈린다 — 어느 지부의 모임과
/// 글을 보여줄지, 로그인 화면으로 돌려보낼지.
class Session {
  const Session({required this.nickname, required this.chapter});

  final String nickname;

  /// 가입할 때 고른 활동 지역.
  ///
  /// 홈에서 보는 지역([currentChapterProvider])의 시작값이 된다. 그쪽은 잠깐
  /// 다른 지부를 구경하러 바뀔 수 있지만 이 값은 계정에 붙어 있다.
  final Chapter chapter;
}
