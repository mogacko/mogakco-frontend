import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/shared/widgets/tag_chip.dart';
import 'package:mogacko/shared/widgets/tag_input_field.dart';

import '../helpers/pump_app.dart';

void main() {
  /// 끊을 데가 없는 긴 값. 하이픈이나 빈칸이 있으면 줄이 알아서 나뉘어
  /// 넘치지 않는다. 진짜 문제는 한 덩어리로 이어진 이름이다.
  const long = 'PostgreSQLReplicationAndShardingToolkitLongName';

  /// 화면 폭. 넘쳤는지 재려면 크기를 고정해야 한다.
  const width = 390.0;
  const padding = 24.0;

  Future<void> pumpField(
    WidgetTester tester, {
    Set<String> selected = const {},
  }) async {
    tester.view
      ..physicalSize = const Size(width, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpScreen(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: padding),
          child: TagInputField(
            suggestions: const ['Spring'],
            selected: selected,
            hintText: '예) Spring',
            onAdd: (_) {},
            onRemove: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 글자가 놓인 자리가 화면 여백 안에 있는지.
  void expectInside(WidgetTester tester, Finder finder) {
    for (final element in finder.evaluate()) {
      final box = element.renderObject! as RenderBox;
      final right = box.localToGlobal(Offset.zero).dx + box.size.width;
      expect(
        right,
        lessThanOrEqualTo(width - padding + 1),
        reason: '알약 밖으로 글자가 나갔다',
      );
    }
  }

  group('태그 입력칸', () {
    testWidgets('담은 값이 길어도 알약 밖으로 나가지 않는다', (tester) async {
      await pumpField(tester, selected: const {long});

      // Flexible 이 없으면 Row 가 글자 길이만큼 벌어지려다 Wrap 이 준 폭에
      // 갇힌다. 테두리는 그 폭에 멈추고 글자만 밖으로 나간다.
      expect(tester.takeException(), isNull);
      expectInside(tester, find.text(long));
    });

    testWidgets('치는 값이 길어도 후보 알약 밖으로 나가지 않는다', (tester) async {
      await pumpField(tester);

      await tester.enterText(find.byType(TextField), long);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expectInside(tester, find.textContaining('추가'));
    });

    testWidgets('넘치는 글자는 말줄임으로 자른다', (tester) async {
      await pumpField(tester, selected: const {long});

      // 방금 친 값은 바로 위 입력칸에 그대로 있다. 알약에서까지 다 보여주려고
      // 세 줄로 늘리면 알약이 아니라 문단이 된다.
      final text = tester.widget<Text>(find.text(long));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });

  group('태그 알약', () {
    testWidgets('프로필의 알약도 한 줄로 자른다', (tester) async {
      tester.view
        ..physicalSize = const Size(width, 844)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpScreen(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Wrap(children: [TagChip(label: long)]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expectInside(tester, find.text(long));
    });
  });
}
