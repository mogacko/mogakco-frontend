import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/community/presentation/community_screen.dart';
import 'package:mogacko/features/event/presentation/event_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_screen.dart';

import '../helpers/pump_app.dart';

/// 목록에서 하나를 눌러 상세로 들어가는 흐름.
///
/// 상세 화면은 id 만 받아 프로바이더를 다시 본다. 객체를 넘기면 상세에서 무엇을
/// 눌러도 화면이 들어올 때의 값을 그대로 들고 있어서, 여기서는 '눌렀더니 값이
/// 따라 바뀌는지'까지 본다.
void main() {
  group('글 상세', () {
    testWidgets('목록에서 글을 누르면 본문과 댓글이 열린다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('3개월 만에 첫 사이드 프로젝트'));
      await tester.pumpAndSettle();

      // 상단 바에 게시판, 본문에 제목과 전체 글.
      expect(find.text('이야기'), findsOneWidget);
      expect(find.textContaining('혼자 했으면 두 번은 접었을'), findsOneWidget);
      expect(find.text('댓글 4'), findsOneWidget);
    });

    testWidgets('댓글을 달면 목록과 개수가 함께 는다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('3개월 만에 첫 사이드 프로젝트'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '축하드립니다!');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.arrow_up));
      await tester.pumpAndSettle();

      expect(find.text('축하드립니다!'), findsOneWidget);
      // 글이 개수를 따로 들고 있지 않아 두 곳이 어긋날 수 없다.
      expect(find.text('댓글 5'), findsOneWidget);
    });

    testWidgets('내가 쓴 댓글만 지울 수 있다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('3개월 만에 첫 사이드 프로젝트'));
      await tester.pumpAndSettle();

      // 목업 댓글 넷 중 내 것은 하나다.
      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.xmark));
      await tester.pumpAndSettle();

      expect(find.text('댓글 3'), findsOneWidget);
    });

    testWidgets('빈 댓글은 보내지 않는다', (tester) async {
      await tester.pumpScreen(const CommunityScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('3개월 만에 첫 사이드 프로젝트'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.arrow_up));
      await tester.pumpAndSettle();

      expect(find.text('댓글 4'), findsOneWidget);
    });
  });

  group('모각코 상세', () {
    testWidgets('카드 위쪽을 누르면 소개와 일정이 열린다', (tester) async {
      await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('모모스커피 온천장'));
      await tester.pumpAndSettle();

      // 목록은 시·도를 떼지만 상세는 그대로 둔다. 지도에 옮겨 붙이는 자리다.
      expect(find.text('부산광역시 동래구 온천동'), findsOneWidget);
      expect(find.textContaining('매주 토·일 오전에 모여'), findsOneWidget);
      expect(find.text('이번 주 일정'), findsOneWidget);
      expect(find.text('모임장'), findsOneWidget);
    });

    testWidgets('상세에서 참여하면 그 자리에서 반영된다', (tester) async {
      await tester.pumpScreen(const MeetupScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.text('모모스커피 온천장'));
      await tester.pumpAndSettle();

      expect(find.text('5/8'), findsOneWidget);

      await tester.tap(find.text('신청').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('참여하기'));
      await tester.pumpAndSettle();

      // id 로 프로바이더를 다시 보므로 화면이 옛 값을 들고 있지 않다.
      expect(find.text('6/8'), findsOneWidget);
      expect(find.text('참여 중'), findsOneWidget);
    });
  });

  group('행사 상세', () {
    testWidgets('카드 위쪽을 누르면 일시·장소·참가비가 줄줄이 열린다', (tester) async {
      await tester.pumpScreen(const EventScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('광안리 야간 산책'));
      await tester.pumpAndSettle();

      // 테스트 화면이 폰보다 넓어 4:3 포스터가 그만큼 커진다. 정보 카드가
      // 뷰포트 아래로 밀리므로 끌어올려 확인한다.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('일시'), findsOneWidget);
      expect(find.text('장소'), findsOneWidget);
      expect(find.text('참가비'), findsOneWidget);
      expect(find.text('정원'), findsOneWidget);
      expect(find.text('신청 마감'), findsOneWidget);
      // 목업에서 미리 신청해 둔 행사라 아래 버튼이 취소로 뜬다.
      expect(find.widgetWithText(FilledButton, '신청 취소'), findsOneWidget);
    });

    testWidgets('상세에서 신청하면 버튼이 취소로 바뀐다', (tester) async {
      await tester.pumpScreen(const EventScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('렌더링 파이프라인'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, '신청하기'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '신청하기'));
      await tester.pumpAndSettle();
      // 시트의 확인 버튼도 같은 글자다. 시트 쪽은 나중에 붙은 것이라 last.
      await tester.tap(find.widgetWithText(FilledButton, '신청하기').last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, '신청 취소'), findsOneWidget);
    });
  });
}
