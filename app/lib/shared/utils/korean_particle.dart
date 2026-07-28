/// 앞 글자의 받침에 따라 갈리는 한국어 조사.
///
/// '제주는'과 '부산은'처럼 조사는 앞말의 받침 유무로 달라진다.
/// 지역명·닉네임처럼 값이 정해지지 않은 말 뒤에 조사를 붙일 때 쓴다.
abstract final class KoreanParticle {
  /// 은/는
  static String topic(String word) => _hasFinalConsonant(word) ? '은' : '는';

  /// 이/가
  static String subject(String word) => _hasFinalConsonant(word) ? '이' : '가';

  /// 을/를
  static String object(String word) => _hasFinalConsonant(word) ? '을' : '를';

  /// 마지막 글자에 받침이 있는지.
  ///
  /// 한글 음절은 (초성, 중성, 종성)이 하나로 합쳐진 코드라
  /// 시작점에서 뺀 값을 28로 나눈 나머지가 종성 번호가 된다. 0이면 받침이 없다.
  /// 한글이 아닌 글자로 끝나면 판단할 수 없어 받침이 없는 것으로 본다.
  static bool _hasFinalConsonant(String word) {
    if (word.isEmpty) return false;
    final code = word.codeUnitAt(word.length - 1);
    const syllableStart = 0xAC00;
    const syllableEnd = 0xD7A3;
    if (code < syllableStart || code > syllableEnd) return false;
    return (code - syllableStart) % 28 != 0;
  }
}
