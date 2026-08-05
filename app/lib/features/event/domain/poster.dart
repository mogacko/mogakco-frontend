import 'dart:typed_data';

/// 행사 포스터.
///
/// 올린 그림과 서버가 준 그림을 한 타입으로 다룬다. 주소 문자열 하나로 두면
/// 방금 기기에서 고른 파일을 담을 데가 없어서, 올리는 화면에서만 따로 들고
/// 다니게 되고 미리보기가 실제로 올라갈 것과 갈린다.
sealed class Poster {
  const Poster();
}

/// 서버가 준 그림.
class RemotePoster extends Poster {
  const RemotePoster(this.url);

  final String url;
}

/// 방금 기기에서 고른 그림. 아직 올라가지 않았다.
///
/// 경로가 아니라 바이트로 들고 있다. 웹에서는 파일 경로가 blob 주소라 앱과
/// 다르게 읽어야 하는데, 바이트는 어느 쪽에서도 같은 방법으로 그려진다.
///
/// 서버가 붙으면 올리기 직전에 이 바이트를 보내고 응답의 주소를 [RemotePoster]
/// 로 바꿔 담는다.
class LocalPoster extends Poster {
  const LocalPoster(this.bytes);

  final Uint8List bytes;
}
