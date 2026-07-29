import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/community/presentation/community_screen.dart';
import 'package:mogacko/features/event/presentation/event_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_screen.dart';

import '../helpers/pump_app.dart';

/// 세 목록 화면이 실제로 당겨지는지 본다.
///
/// 새로고침이 무엇을 지키는지는 refresh_test 가 본다. 여기서는 배선만 본다 —
/// 스크롤 물리를 되돌리거나 [RefreshIndicator] 를 빠뜨리면 당겨지지 않는데,
/// 화면은 멀쩡해 보여서 눈으로는 놓치기 쉽다.
void main() {
  final screens = <String, Widget>{
    '커뮤니티': const CommunityScreen(),
    '모각코': const MeetupScreen(),
    '행사': const EventScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} 목록을 당기면 맨 위에서 스피너가 돈다', (tester) async {
      // 스피너는 애니메이션이라 꺼 두면 나타나지 않는다.
      await tester.pumpScreen(entry.value, animations: true);
      await tester.pump(const Duration(milliseconds: 400));

      await tester.fling(
        find.byType(Scrollable).last,
        const Offset(0, 320),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      // 목업이 서버인 척하는 시간이 지나면 걷힌다.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });
  }
}
