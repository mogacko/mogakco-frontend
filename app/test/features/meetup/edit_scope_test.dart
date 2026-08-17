import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/meetup/domain/edit_scope.dart';
import 'package:mogacko/features/meetup/presentation/meetup_edit_screen.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';

import '../../helpers/pump_app.dart';

extension on WidgetTester {
  /// 고치기 화면을 연다.
  ///
  /// 화면을 길게 잡는다. 기본 800x600 에서는 날짜 행이 접힌 목록 아래로
  /// 내려가 아직 지어지지 않는데, 그러면 '찾을 수 없다'가 뜬다. 화면이
  /// 잘못된 게 아니라 아직 없는 것이다.
  Future<ProviderContainer> openEdit(String meetupId) {
    view
      ..physicalSize = const Size(400, 1800)
      ..devicePixelRatio = 1.0;
    addTearDown(view.reset);
    return pumpScreen(MeetupEditScreen(meetupId: meetupId));
  }

  /// 정원을 하나 올린다. 첫 날짜 행의 '+'.
  Future<void> bumpCapacity() async {
    await tap(find.byIcon(Icons.add).first);
    await pump();
  }

  Future<void> save() async {
    await tap(find.text('저장'));
    await pumpAndSettle();
  }
}

/// 범위를 언제 묻고 언제 안 묻는지 본다.
///
/// 물어야 할 때 안 물으면 다음 주에 참여자가 엉뚱한 곳으로 가고, 안 물어도 될
/// 때 물으면 금방 안 읽고 누르게 된다. 그러면 정작 필요할 때도 안 읽는다.
void main() {
  /// evan 이 연 정기 모임. 금·토 이틀이다.
  const recurring = 'busan-3';

  group('정기 모각코를 고칠 때', () {
    testWidgets('소개만 바꾸면 묻지 않는다', (tester) async {
      final container = await tester.openEdit(recurring);

      await tester.enterText(
        find.byType(TextField).last,
        '이번 주는 2층에서 모여요',
      );
      await tester.pump();
      await tester.save();

      // 이번 주만 다른 소개를 쓸 이유가 없다.
      expect(find.text(EditScope.thisWeek.label), findsNothing);

      final saved = container
          .read(meetupListProvider)
          .firstWhere((meetup) => meetup.id == recurring);
      expect(saved.description, '이번 주는 2층에서 모여요');
    });

    testWidgets('정원을 바꾸면 어디까지 미칠지 묻는다', (tester) async {
      await tester.openEdit(recurring);

      await tester.bumpCapacity();
      await tester.save();

      expect(find.text(EditScope.thisWeek.label), findsOneWidget);
      expect(find.text(EditScope.forward.label), findsOneWidget);
    });

    testWidgets('그만두면 아무것도 바뀌지 않는다', (tester) async {
      final container = await tester.openEdit(recurring);
      final before = container
          .read(meetupListProvider)
          .firstWhere((meetup) => meetup.id == recurring)
          .sessions
          .first
          .capacity;

      await tester.bumpCapacity();
      await tester.save();

      await tester.tap(find.text('그만두기'));
      await tester.pumpAndSettle();

      final after = container
          .read(meetupListProvider)
          .firstWhere((meetup) => meetup.id == recurring)
          .sessions
          .first
          .capacity;
      expect(after, before);
    });

    testWidgets('이번 주만 고르면 그 뜻이 드러나게 알려준다', (tester) async {
      await tester.openEdit(recurring);

      await tester.bumpCapacity();
      await tester.save();

      await tester.tap(find.text(EditScope.thisWeek.label));
      await tester.pumpAndSettle();

      expect(find.text('이번 주 모각코만 바꿨어요'), findsOneWidget);
    });
  });

  group('정기가 아닌 모각코', () {
    testWidgets('무엇을 바꾸든 묻지 않는다', (tester) async {
      // busan-2 는 정기가 아니지만 남이 연 것이라 목록을 거치지 않고 바로 연다.
      final container = await tester.openEdit('busan-2');

      await tester.bumpCapacity();
      await tester.save();

      // 앞으로가 없으니 고를 것도 없다.
      expect(find.text(EditScope.thisWeek.label), findsNothing);
      expect(
        container.read(meetupListProvider).any((meetup) => meetup.id == 'busan-2'),
        isTrue,
      );
    });
  });
}
