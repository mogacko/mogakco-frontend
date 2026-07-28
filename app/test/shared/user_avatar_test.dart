import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/shared/widgets/user_avatar.dart';

import '../helpers/pump_app.dart';

void main() {
  group('UserAvatar', () {
    testWidgets('사진이 없으면 닉네임 첫 글자를 보여준다', (tester) async {
      await tester.pumpScreen(
        const Center(child: UserAvatar(name: '재현', size: 24)),
      );

      expect(find.text('재'), findsOneWidget);
    });

    testWidgets('라틴 문자는 대문자로 올린다', (tester) async {
      await tester.pumpScreen(
        const Center(child: UserAvatar(name: 'evan', size: 24)),
      );

      expect(find.text('E'), findsOneWidget);
    });

    testWidgets('이름이 비어도 자리를 지킨다', (tester) async {
      await tester.pumpScreen(
        const Center(child: UserAvatar(name: '  ', size: 24)),
      );

      expect(find.text('?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('사진을 못 불러오면 이니셜로 되돌린다', (tester) async {
      // 테스트 환경에서는 네트워크 요청이 막혀 곧바로 오류로 떨어진다.
      await tester.pumpScreen(
        const Center(
          child: UserAvatar(
            name: '수민',
            size: 24,
            imageUrl: 'https://example.invalid/avatar.png',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('수'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('동그랗게 잘라 그린다', (tester) async {
      await tester.pumpScreen(
        const Center(child: UserAvatar(name: '지우', size: 32)),
      );

      expect(find.byType(ClipOval), findsOneWidget);
      final box = tester.getSize(find.byType(ClipOval));
      expect(box.width, 32);
      expect(box.height, 32);
    });
  });
}
