import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/auth/presentation/session_provider.dart';
import 'package:mogacko/features/meetup/domain/meetup.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/profile/presentation/withdraw_screen.dart';
import 'package:mogacko/shared/providers/now_provider.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('회원 탈퇴', () {
    Finder button() => find.widgetWithText(FilledButton, '탈퇴하기');

    testWidgets('확인하기 전에는 누를 수 없다', (tester) async {
      await tester.pumpScreen(const WithdrawScreen());
      await tester.pumpAndSettle();

      // '정말요?' 한 번 누르고 계정이 사라지면 되돌릴 수 없는 일치고는 가볍다.
      expect(tester.widget<FilledButton>(button()).onPressed, isNull);

      await tester.tap(find.text('위 내용을 모두 확인했어요'));
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(button()).onPressed, isNotNull);
    });

    testWidgets('무엇이 지워지는지 다 적는다', (tester) async {
      await tester.pumpScreen(const WithdrawScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('되돌릴 수 없어요'), findsWidgets);
      expect(find.textContaining('함께 지워져요'), findsOneWidget);
      expect(find.textContaining('모두 취소돼요'), findsOneWidget);
    });

    testWidgets('열어둔 모각코가 있으면 먼저 알린다', (tester) async {
      await tester.pumpScreen(const WithdrawScreen());
      await tester.pumpAndSettle();

      // 탈퇴하고 나서 오기로 했던 사람들이 빈 카페에 모이면 안 된다.
      expect(find.textContaining('아직 열려 있는 모각코가'), findsOneWidget);
    });

    testWidgets('열어둔 모각코를 접으면 그 안내가 사라진다', (tester) async {
      final container = await tester.pumpScreen(const WithdrawScreen());
      await tester.pumpAndSettle();

      final now = container.read(nowProvider);
      final mine = container
          .read(meetupListProvider)
          .where((meetup) => meetup.host == 'evan')
          .toList();
      for (final meetup in mine) {
        container
            .read(meetupListProvider.notifier)
            .cancel(
              meetup.id,
              Cancellation(reason: CancelReason.personal, at: now),
            );
      }
      await tester.pumpAndSettle();

      expect(find.textContaining('아직 열려 있는 모각코가'), findsNothing);
    });

    testWidgets('탈퇴하면 세션이 비고 라우터가 로그인으로 돌린다', (tester) async {
      final container = await tester.pumpScreen(const WithdrawScreen());
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider), isNotNull);

      await tester.tap(find.text('위 내용을 모두 확인했어요'));
      await tester.pumpAndSettle();
      await tester.tap(button());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '탈퇴'));
      await tester.pumpAndSettle();

      // 이동을 두 곳에서 정하면 언젠가 어긋난다. 세션만 비운다.
      expect(container.read(sessionProvider), isNull);
    });

    testWidgets('확인 시트에서 물러나면 그대로 남는다', (tester) async {
      final container = await tester.pumpScreen(const WithdrawScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('위 내용을 모두 확인했어요'));
      await tester.pumpAndSettle();
      await tester.tap(button());
      await tester.pumpAndSettle();
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();

      expect(container.read(sessionProvider), isNotNull);
    });
  });
}
