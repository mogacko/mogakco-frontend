import 'dart:async';

import 'package:dio/dio.dart';

import 'auth_tokens.dart';
import 'token_store.dart';

/// 요청에 토큰을 싣고, 만료되면 조용히 되살린다.
///
/// 웹은 브라우저가 쿠키를 알아서 붙여주지만 앱은 매 요청에 직접 붙여야 한다.
/// 화면마다 적으면 한 곳만 빠뜨려도 그 요청만 401 이 나는데, 원인을 찾기가
/// 나중일수록 어렵다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.store,
    required this.refresh,
    required this.onSignedOut,
  });

  final TokenStore store;

  /// 재발급을 실제로 수행하는 함수.
  ///
  /// 이 인터셉터가 붙지 않은 별도 통로로 불러야 한다. 재발급 요청이 스스로
  /// 이 인터셉터를 타면 그 요청의 401 이 다시 재발급을 부르며 끝없이 돈다.
  ///
  /// 되살릴 수 없으면 null 을 준다.
  final Future<AuthTokens?> Function(AuthTokens current) refresh;

  /// 되살리지 못했을 때. 저장소를 비우고 로그인 화면으로 보낼 자리다.
  final void Function() onSignedOut;

  /// 되살린 뒤 원래 요청을 다시 보낼 통로.
  ///
  /// 이 인터셉터가 붙은 바로 그 Dio 다. 새 Dio 를 만들어 보내면 헤더를 붙이는
  /// 이 인터셉터를 안 타서, 되살린 토큰이 실리지 않는다.
  late final Dio client;

  /// 지금 돌고 있는 재발급.
  ///
  /// 홈을 열면 모임·행사·인기글·알림이 한꺼번에 나간다. 토큰이 막 만료된
  /// 순간이면 넷 다 401 을 받는데, 각자 재발급을 부르면 같은 리프레시 토큰이
  /// 네 번 서버로 간다. 서버가 재사용을 탈취로 보면 정상 사용 중인 사람이
  /// 쫓겨난다. 한 번만 돌리고 나머지는 그 결과를 기다린다.
  Future<AuthTokens?>? _inFlight;

  /// 이미 되살려 다시 보낸 요청인지. 두 번은 하지 않는다.
  static const _retriedKey = 'auth.retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await store.read();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final retried = options.extra[_retriedKey] == true;

    if (err.response?.statusCode != 401 || retried) {
      handler.next(err);
      return;
    }

    final current = await store.read();
    if (current == null) {
      handler.next(err);
      return;
    }

    final tokens = await _refreshOnce(current);
    if (tokens == null) {
      await store.clear();
      onSignedOut();
      handler.next(err);
      return;
    }

    try {
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      final retry = await client.fetch<dynamic>(options);
      handler.resolve(retry);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  Future<AuthTokens?> _refreshOnce(AuthTokens current) {
    // 이미 돌고 있으면 그 결과를 같이 받는다.
    final running = _inFlight;
    if (running != null) return running;

    final started = _run(current);
    _inFlight = started;
    return started;
  }

  Future<AuthTokens?> _run(AuthTokens current) async {
    try {
      final next = await refresh(current);
      if (next != null) await store.write(next);
      return next;
    } catch (_) {
      return null;
    } finally {
      _inFlight = null;
    }
  }
}
