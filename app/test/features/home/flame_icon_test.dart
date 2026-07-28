import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/home/presentation/widgets/flame_icon.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('FlameIcon', () {
    /// 화면에 그려진 실제 배율
    double scaleOf(WidgetTester tester) {
      final transform = tester.widget<Transform>(
        find
            .ancestor(of: find.byType(Icon), matching: find.byType(Transform))
            .first,
      );
      return transform.transform.getMaxScaleOnAxis();
    }

    testWidgets('시간이 지나면 크기가 변한다', (tester) async {
      await tester.pumpScreen(
        const FlameIcon(color: Colors.red),
        animations: true,
      );

      await tester.pump(const Duration(milliseconds: 100));
      final first = scaleOf(tester);

      await tester.pump(const Duration(milliseconds: 450));
      final second = scaleOf(tester);

      expect(second, isNot(closeTo(first, 0.01)));

      // 무한 반복이라 pumpAndSettle 대신 위젯을 걷어 타이머를 정리한다.
      await tester.pumpScreen(const SizedBox());
    });

    testWidgets('배율이 정해둔 범위를 넘지 않는다', (tester) async {
      await tester.pumpScreen(
        const FlameIcon(color: Colors.red),
        animations: true,
      );

      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final scale = scaleOf(tester);
        expect(scale, greaterThanOrEqualTo(0.99));
        expect(scale, lessThanOrEqualTo(1.17));
      }

      await tester.pumpScreen(const SizedBox());
    });

    testWidgets('애니메이션 줄이기를 켜면 멈춘 아이콘만 그린다', (tester) async {
      await tester.pumpScreen(const FlameIcon(color: Colors.red));
      await tester.pumpAndSettle();

      // 정지 상태에서는 변형 자체가 없어야 pumpAndSettle 이 끝난다.
      expect(find.byType(ScaleTransition), findsNothing);
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
