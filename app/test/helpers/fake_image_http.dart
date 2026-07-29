import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 이미지 요청만 받아주는 가짜 HttpClient 를 건다.
///
/// 테스트 환경의 기본 HttpClient 는 어떤 요청에도 400 을 돌려준다. 그러면
/// 포스터 자리에 늘 대체 표시만 남아서, 골든으로 배치를 확인할 수 없다.
///
/// 반드시 [TestWidgetsFlutterBinding.ensureInitialized] 뒤에 불러야 한다.
/// 바인딩이 만들어질 때 자기 것으로 덮어쓰기 때문이다
/// (flutter_test/src/binding.dart 의 `setupHttpOverrides`).
///
/// zone 으로 거는 방법(`HttpOverrides.runZoned`)은 여기서 소용이 없다.
/// flutter_test_config 의 testExecutable 은 테스트를 등록만 하고, 본문은
/// 나중에 러너의 zone 에서 돌아 그 zone 을 벗어난다.
void installFakeImageHttpClient() {
  HttpOverrides.global = _ImageHttpOverrides();
}

class _ImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

/// 1x1 PNG. 늘려 깔면 한 가지 색으로 자리를 채운다.
final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGOYtWQHAAPS'
  'Afeq+rUAAAAAAElFTkSuQmCC',
);

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpRequest(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpRequest(url);

  @override
  void close({bool force = false}) {}

  // 이미지 조회 외에는 쓰이지 않는다. 쓰이면 그때 채운다.
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpRequest implements HttpClientRequest {
  _FakeHttpRequest(this.uri);

  @override
  final Uri uri;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpResponse();

  @override
  Future<HttpClientResponse> get done async => _FakeHttpResponse();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpResponse implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _pixel.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<Uint8List>.value(_pixel).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
