import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_tokens.dart';

/// 토큰을 기기에 둔다.
///
/// 일반 저장소가 아니라 Keychain(iOS) · Keystore(Android)에 넣는다. 앱을
/// 지우기 전까지 남아 있어야 하고, 다른 앱이나 백업으로 새어 나가면 안 된다.
abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _access = 'auth.accessToken';
  static const _refresh = 'auth.refreshToken';

  @override
  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _access);
    final refresh = await _storage.read(key: _refresh);

    // 둘 중 하나만 있으면 쓸 수 없다. 액세스만 있으면 만료된 뒤 되살릴 길이
    // 없고, 리프레시만 있으면 당장 부를 요청이 없다.
    if (access == null || refresh == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _access, value: tokens.accessToken);
    await _storage.write(key: _refresh, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }
}

/// 시험대와 개발용. 기기에 남기지 않는다.
class InMemoryTokenStore implements TokenStore {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
