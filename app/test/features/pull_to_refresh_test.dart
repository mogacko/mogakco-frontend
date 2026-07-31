import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/community/presentation/community_screen.dart';
import 'package:mogacko/features/event/presentation/event_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_screen.dart';

import '../helpers/pump_app.dart';

/// 세 목록 화면이 실제로 당겨지는지 본다.
///
/// 새로고침이 무엇을 지키는지는 refresh_test 가 본다. 여기서는 배선만 본다 —
/// 스크롤 물리를 되돌리거나 [CupertinoSliverRefreshControl] 을 빠뜨리면
/// 당겨지지 않는데, 화면은 멀쩡해 보여서 눈으로는 놓치기 쉽다.
void main() {
  final screens = <String, Widget>{
    '커뮤니티': const CommunityScreen(),
    '모각코': const MeetupScreen(),
    '행사': const EventScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} 목록을 당기면 그 자리에서 스피너가 돈다', (tester) async {
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

      // 머티리얼처럼 목록 위에 떠 있는 게 아니라 당겨서 열린 자리에서 돈다.
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      // 목업이 서버인 척하는 시간이 지나면 걷히고 목록이 도로 올라온다.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });
  }

  testWidgets('상세 화면도 당겨진다', (tester) async {
    // 댓글이 달리고 정원이 차는 자리라 목록보다 더 필요하다.
    await tester.pumpScreen(const MeetupScreen(), animations: true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('모모스커피 온천장'));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 320),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoActivityIndicator), findsNothing);
  });

  testWidgets('당기지 않았을 때는 목록이 맨 위에 붙어 있다', (tester) async {
    await tester.pumpScreen(const MeetupScreen(), animations: true);
    await tester.pumpAndSettle();

    // 열린 자리가 없으면 스피너도 없다. 자리를 늘 비워 두면 첫 항목이
    // 그만큼 아래에서 시작한다.
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
  });
}
