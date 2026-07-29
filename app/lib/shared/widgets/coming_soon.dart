import 'package:flutter/material.dart';

/// 아직 만들지 않은 화면으로 가는 자리에서 쓰는 안내.
///
/// 버튼을 아예 빼면 설계가 달라 보이고, 눌러도 아무 일이 없으면 고장 난
/// 것처럼 보인다. 무엇이 아직 없는지 짧게 알리고 물러난다.
///
/// 그 화면을 만들 때 이 호출을 실제 이동으로 바꾸면 된다. 남아 있는 호출부가
/// 곧 남은 할 일 목록이다.
void showComingSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('$what 화면은 준비 중이에요'),
        duration: const Duration(seconds: 2),
      ),
    );
}
