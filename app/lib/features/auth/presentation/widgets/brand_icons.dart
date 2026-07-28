import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 소셜 로그인 제공자 아이콘.
///
/// 구글은 공식 4색 마크라 색을 바꾸지 않는다. 카카오는 버튼 전경색을 따라야 해서
/// currentColor 대신 colorFilter로 덧칠한다.
///
/// 카카오 심볼은 공식 배포 에셋이 아니라 형태를 근사한 것이다.
/// 스토어 출시 전 developers.kakao.com의 공식 심볼로 교체해야 한다.
abstract final class BrandIcons {
  static const _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18">
  <path fill="#4285F4" d="M17.64 9.2045c0-.6381-.0573-1.2518-.1636-1.8409H9v3.4814h4.8436c-.2086 1.125-.8427 2.0782-1.7959 2.7164v2.2581h2.9087c1.7018-1.5668 2.6836-3.874 2.6836-6.615z"/>
  <path fill="#34A853" d="M9 18c2.43 0 4.4673-.806 5.9564-2.1805l-2.9087-2.2581c-.8059.54-1.8368.8591-3.0477.8591-2.344 0-4.3282-1.5831-5.036-3.7104H.9574v2.3318C2.4382 15.9832 5.4818 18 9 18z"/>
  <path fill="#FBBC05" d="M3.964 10.71c-.18-.54-.2822-1.1168-.2822-1.71s.1022-1.17.2823-1.71V4.9582H.9573A8.9965 8.9965 0 0 0 0 9c0 1.4523.3477 2.8268.9573 4.0418L3.964 10.71z"/>
  <path fill="#EA4335" d="M9 3.5795c1.3214 0 2.5077.4541 3.4405 1.346l2.5813-2.5814C13.4632.8918 11.426 0 9 0 5.4818 0 2.4382 2.0168.9573 4.9582L3.964 7.29C4.6718 5.1627 6.6559 3.5795 9 3.5795z"/>
</svg>
''';

  static const _kakaoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#000000" d="M12 3.5C7.03 3.5 3 6.64 3 10.51c0 2.5 1.68 4.7 4.2 5.93-.18.65-.67 2.42-.77 2.8-.12.47.17.46.36.33.15-.1 2.37-1.6 3.33-2.25.6.09 1.22.13 1.88.13 4.97 0 9-3.14 9-7.01S16.97 3.5 12 3.5z"/>
</svg>
''';

  static Widget google({double size = 20}) {
    return SvgPicture.string(_googleSvg, width: size, height: size);
  }

  static Widget kakao({required Color color, double size = 20}) {
    return SvgPicture.string(
      _kakaoSvg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static Widget apple({required Color color, double size = 22}) {
    return Icon(Icons.apple, color: color, size: size);
  }
}
