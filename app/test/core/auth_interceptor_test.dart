import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/core/network/auth_interceptor.dart';
import 'package:mogacko/core/network/auth_tokens.dart';
import 'package:mogacko/core/network/token_store.dart';

/// 서버 대신 정해진 답을 주는 통로.
///
/// 인터셉터가 아니라 어댑터로 둔다. 인터셉터로 만들면 거절이 진짜 응답이
/// 아니라서 401 이 [AuthInterceptor.onError] 까지 닿지 않는다.
///
/// 액세스 토큰이 [valid] 와 다르면 401 을 뱉는다. 재발급이 실제로 헤더를
/// 갈아끼웠는지를 이걸로 가린다.
class _FakeServer implements HttpClientAdapter {
  _FakeServer(this.valid);

  String valid;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    final ok = options.headers['Authorization'] == 'Bearer $valid';
    return ResponseBody.fromString(
      '{}',
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late InMemoryTokenStore store;
  late _FakeServer server;

  setUp(() {
    store = InMemoryTokenStore();
    server = _FakeServer('new');
  });

  /// 재발급이 성공하는 통로.
  Dio dioWith({
    required Future<AuthTokens?> Function(AuthTokens) refresh,
    void Function()? onSignedOut,
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final interceptor = AuthInterceptor(
      store: store,
      refresh: refresh,
      onSignedOut: onSignedOut ?? () {},
    );
    interceptor.client = dio;
    dio.interceptors.add(interceptor);
    dio.httpClientAdapter = server;
    return dio;
  }

  group('토큰 싣기', () {
    test('토큰이 있으면 Authorization 을 붙인다', () async {
      await store.write(
        const AuthTokens(accessToken: 'new', refreshToken: 'r'),
      );
      final dio = dioWith(refresh: (_) async => null);

      final res = await dio.get<dynamic>('/me');

      expect(res.statusCode, 200);
      expect(server.calls, 1);
    });

    test('토큰이 없으면 붙이지 않는다', () async {
      final dio = dioWith(refresh: (_) async => null);

      await expectLater(dio.get<dynamic>('/me'), throwsA(isA<DioException>()));
    });
  });

  group('재발급', () {
    test('401 이면 되살리고 그 요청을 다시 보낸다', () async {
      await store.write(
        const AuthTokens(accessToken: 'old', refreshToken: 'r'),
      );
      final dio = dioWith(
        refresh: (current) async =>
            current.refreshed(access: 'new', refresh: 'r2'),
      );

      final res = await dio.get<dynamic>('/me');

      expect(res.statusCode, 200);
      // 처음 한 번 401, 되살린 뒤 한 번 더.
      expect(server.calls, 2);
      final saved = await store.read();
      expect(saved!.accessToken, 'new');
      expect(saved.refreshToken, 'r2');
    });

    test('리프레시가 안 오면 쓰던 것을 그대로 둔다', () async {
      await store.write(
        const AuthTokens(accessToken: 'old', refreshToken: 'keep'),
      );
      final dio = dioWith(
        // 서버가 갱신할 때만 리프레시를 준다. 없다고 지우면 저장소가 비어
        // 정상 사용 중에 로그아웃된다.
        refresh: (current) async => current.refreshed(access: 'new'),
      );

      await dio.get<dynamic>('/me');

      expect((await store.read())!.refreshToken, 'keep');
    });

    test('되살리지 못하면 저장소를 비우고 알린다', () async {
      await store.write(
        const AuthTokens(accessToken: 'old', refreshToken: 'r'),
      );
      var signedOut = false;
      final dio = dioWith(
        refresh: (_) async => null,
        onSignedOut: () => signedOut = true,
      );

      await expectLater(dio.get<dynamic>('/me'), throwsA(isA<DioException>()));

      expect(signedOut, isTrue);
      expect(await store.read(), isNull);
    });

    test('되살린 뒤에도 401 이면 두 번 시도하지 않는다', () async {
      await store.write(
        const AuthTokens(accessToken: 'old', refreshToken: 'r'),
      );
      var refreshes = 0;
      final dio = dioWith(
        refresh: (current) async {
          refreshes++;
          // 여전히 서버가 아는 값과 다르다.
          return current.refreshed(access: 'still-wrong');
        },
      );

      await expectLater(dio.get<dynamic>('/me'), throwsA(isA<DioException>()));

      expect(refreshes, 1);
      expect(server.calls, 2);
    });
  });

  group('동시 401', () {
    test('네 요청이 한꺼번에 401 을 받아도 재발급은 한 번', () async {
      await store.write(
        const AuthTokens(accessToken: 'old', refreshToken: 'r'),
      );

      var refreshes = 0;
      final dio = dioWith(
        refresh: (current) async {
          refreshes++;
          // 첫 재발급이 도는 동안 나머지 셋이 몰려들 만큼은 붙잡아 둔다.
          // 나머지 과정은 전부 메모리 안이라 이 정도면 넉넉하다.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return current.refreshed(access: 'new');
        },
      );

      final results = await Future.wait([
        dio.get<dynamic>('/a'),
        dio.get<dynamic>('/b'),
        dio.get<dynamic>('/c'),
        dio.get<dynamic>('/d'),
      ]);

      // 같은 리프레시 토큰이 네 번 가면 서버가 탈취로 보고 세션을 끊는다.
      expect(refreshes, 1);
      expect(results.every((res) => res.statusCode == 200), isTrue);
    });
  });
}
