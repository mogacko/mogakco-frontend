/// 서버가 내준 우리 앱의 토큰 한 쌍.
///
/// 소셜 제공자의 토큰과는 다르다. 그쪽은 로그인할 때 한 번 쓰고 버리고,
/// 이후 모든 요청은 이 토큰만 쓴다.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  /// 재발급 응답을 반영한 새 한 쌍.
  ///
  /// 서버는 리프레시를 갱신할 때만 함께 내려준다. 안 왔다고 지우면 저장소에서
  /// 토큰이 사라져 정상 사용 중에 로그아웃된다 — 오면 갈아끼우고 없으면
  /// 쓰던 것을 그대로 둔다.
  AuthTokens refreshed({required String access, String? refresh}) {
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh ?? refreshToken,
    );
  }
}
