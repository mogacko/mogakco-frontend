import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/chapter.dart';
import '../../profile/data/mock_profile.dart';
import '../domain/session.dart';

/// 로그인 상태.
///
/// null 이면 로그아웃. 라우터가 이 값을 보고 로그인 화면과 홈 사이를 가른다.
///
/// 아직 기기에 남기지 않는다. 앱을 다시 켜면 로그아웃된 채로 시작한다.
/// 서버와 토큰이 붙을 때 저장을 함께 붙인다.
class SessionState extends Notifier<Session?> {
  @override
  Session? build() => null;

  /// 가입을 마쳤거나 로그인했다.
  ///
  /// 지역은 가입 화면에서 고른 것을 받는다. 아직 소셜 로그인이 없어 닉네임은
  /// 목업 값을 쓴다.
  void signIn({required Chapter chapter}) {
    state = Session(nickname: MockProfile.nickname, chapter: chapter);
  }

  void signOut() => state = null;
}

final sessionProvider = NotifierProvider<SessionState, Session?>(
  SessionState.new,
);

/// 가입 도중 고른 지역.
///
/// 지역 선택과 가입 완료가 다른 화면이라 그 사이에 값을 들고 있을 데가
/// 필요하다. 가입을 마치면 세션으로 옮겨 가고 여기서는 쓰이지 않는다.
class SignupChapter extends Notifier<Chapter?> {
  @override
  Chapter? build() => null;

  void select(Chapter chapter) => state = chapter;
}

final signupChapterProvider = NotifierProvider<SignupChapter, Chapter?>(
  SignupChapter.new,
);
