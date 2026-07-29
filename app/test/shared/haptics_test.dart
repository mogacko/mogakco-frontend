import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/community/presentation/community_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_screen.dart';

import '../helpers/pump_app.dart';

/// 어디서 울리고 어디서 울리지 않는지가 곧 정책이다.
///
/// 함부로 늘어나면 금세 성가셔지는 종류라, 자리를 넓히려면 여기 테스트부터
/// 고쳐야 하게 둔다.
void main() {
  late List<String> fired;

  setUp(() {
    fired = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            fired.add(call.arguments as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('결정하는 순간', () {
    testWidgets('참여를 확정하면 울린다', (tester) async {
      await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('신청').first);
      await tester.pumpAndSettle();
      // 시트를 여는 것만으로는 아직 아무것도 정해지지 않았다.
      expect(fired, isEmpty);

      await tester.tap(find.text('참여하기'));
      await tester.pumpAndSettle();

      expect(fired, ['HapticFeedbackType.mediumImpact']);
    });

    testWidgets('물러나면 울리지 않는다', (tester) async {
      await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('신청').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();

      expect(fired, isEmpty);
    });
  });

  group('가볍게 켜고 끄는 반응', () {
    testWidgets('좋아요를 켤 때는 결정보다 약하게 울린다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.heart).first);
      await tester.pumpAndSettle();

      expect(fired, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('좋아요를 끌 때는 울리지 않는다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      // 취소는 축하할 일이 아니다. 손끝 반응도 켤 때만 준다.
      await tester.tap(find.byIcon(CupertinoIcons.heart_fill).first);
      await tester.pumpAndSettle();

      expect(fired, isEmpty);
    });
  });
}
