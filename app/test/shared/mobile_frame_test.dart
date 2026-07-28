import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/shared/widgets/mobile_frame.dart';

import '../helpers/pump_app.dart';

void main() {
  group('MobileFrame', () {
    /// 안쪽 내용이 실제로 차지한 폭
    double innerWidth(WidgetTester tester) =>
        tester.getSize(find.byKey(const Key('content'))).width;

    Widget content() => const SizedBox.expand(key: Key('content'));

    testWidgets('폰 폭에서는 그대로 둔다', (tester) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpScreen(MobileFrame(child: content()));

      expect(innerWidth(tester), 390);
    });

    testWidgets('넓은 화면에서는 폭을 묶는다', (tester) async {
      tester.view
        ..physicalSize = const Size(1440, 900)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpScreen(MobileFrame(child: content()));

      expect(innerWidth(tester), 460);
    });

    testWidgets('묶은 폭을 MediaQuery 에도 알려준다', (tester) async {
      tester.view
        ..physicalSize = const Size(1440, 900)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late double reported;
      await tester.pumpScreen(
        MobileFrame(
          child: Builder(
            builder: (context) {
              reported = MediaQuery.of(context).size.width;
              return content();
            },
          ),
        ),
      );

      // 브라우저 폭이 아니라 앱이 실제로 쓰는 폭이어야 안쪽 계산이 맞는다.
      expect(reported, 460);
    });

    testWidgets('가운데에 세운다', (tester) async {
      tester.view
        ..physicalSize = const Size(1440, 900)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpScreen(MobileFrame(child: content()));

      final rect = tester.getRect(find.byKey(const Key('content')));
      expect(rect.center.dx, moreOrLessEquals(720, epsilon: 1));
    });
  });
}
