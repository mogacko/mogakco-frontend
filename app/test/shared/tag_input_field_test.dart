import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/shared/widgets/tag_input_field.dart';

import '../helpers/pump_app.dart';

/// 서버 추천을 흉내내는 테스트용 화면.
class _Host extends StatefulWidget {
  const _Host({
    required this.onSearch,
    this.debounce = const Duration(seconds: 1),
  });

  final TagSearch onSearch;
  final Duration debounce;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TagInputField(
          key: const Key('tags'),
          suggestions: const ['Java', 'Spring'],
          selected: _selected,
          hintText: '입력',
          onSearch: widget.onSearch,
          searchDebounce: widget.debounce,
          onAdd: (v) => setState(() => _selected.add(v)),
          onRemove: (v) => setState(() => _selected.remove(v)),
        ),
      ),
    );
  }
}

void main() {
  group('TagInputField 서버 추천', () {
    final input = find.byType(TextField);

    testWidgets('디바운스 시간 전에는 서버를 부르지 않는다', (tester) async {
      var calls = 0;
      await tester.pumpScreen(
        _Host(
          onSearch: (q) async {
            calls++;
            return ['원격-$q'];
          },
        ),
      );

      await tester.enterText(input, 'Sv');
      await tester.pump(const Duration(milliseconds: 900));

      expect(calls, 0);

      await tester.pump(const Duration(milliseconds: 200));
      expect(calls, 1);
    });

    testWidgets('연속으로 치면 마지막 한 번만 요청한다', (tester) async {
      var calls = 0;
      final queries = <String>[];
      await tester.pumpScreen(
        _Host(
          onSearch: (q) async {
            calls++;
            queries.add(q);
            return const [];
          },
        ),
      );

      for (final text in ['S', 'Sv', 'Sve', 'Svel']) {
        await tester.enterText(input, text);
        await tester.pump(const Duration(milliseconds: 300));
      }
      await tester.pump(const Duration(seconds: 1));

      expect(calls, 1);
      expect(queries, ['Svel']);
    });

    testWidgets('로컬 추천은 디바운스와 무관하게 즉시 뜬다', (tester) async {
      await tester.pumpScreen(_Host(onSearch: (q) async => const []));

      await tester.enterText(input, 'Ja');
      await tester.pump();

      // 서버를 기다리지 않고 내장 목록에서 바로 나와야 한다.
      expect(find.text('Java'), findsOneWidget);
    });

    testWidgets('서버 추천이 로컬 목록과 함께 뜬다', (tester) async {
      await tester.pumpScreen(_Host(onSearch: (q) async => const ['Svelte']));

      await tester.enterText(input, 'S');
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Spring'), findsOneWidget);
      expect(find.text('Svelte'), findsOneWidget);
    });

    testWidgets('서버가 준 표기로 정규화한다', (tester) async {
      await tester.pumpScreen(_Host(onSearch: (q) async => const ['Svelte']));

      await tester.enterText(input, 'svelte');
      await tester.pump(const Duration(seconds: 2));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final field = tester.widget<TagInputField>(find.byKey(const Key('tags')));
      expect(field.selected, contains('Svelte'));
      expect(field.selected, isNot(contains('svelte')));
    });

    testWidgets('서버 응답이 늦어도 최신 입력 결과를 덮지 않는다', (tester) async {
      await tester.pumpScreen(
        _Host(
          debounce: const Duration(milliseconds: 100),
          onSearch: (q) async {
            // 첫 요청만 느리게 응답시켜 순서를 뒤집는다.
            await Future<void>.delayed(
              q == 'A' ? const Duration(seconds: 3) : Duration.zero,
            );
            return ['결과-$q'];
          },
        ),
      );

      await tester.enterText(input, 'A');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.enterText(input, 'B');
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(seconds: 4));

      // 늦게 도착한 'A' 결과가 'B' 결과를 밀어내면 안 된다.
      expect(find.text('결과-B'), findsOneWidget);
      expect(find.text('결과-A'), findsNothing);
    });

    testWidgets('서버 조회가 실패해도 입력을 막지 않는다', (tester) async {
      await tester.pumpScreen(
        _Host(onSearch: (q) async => throw Exception('네트워크 끊김')),
      );

      await tester.enterText(input, 'Ja');
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
      expect(find.text('Java'), findsOneWidget);
    });

    testWidgets('입력 도중 화면이 사라져도 타이머가 터지지 않는다', (tester) async {
      await tester.pumpScreen(_Host(onSearch: (q) async => const ['Svelte']));

      await tester.enterText(input, 'Sv');
      await tester.pump(const Duration(milliseconds: 200));

      // 디바운스가 끝나기 전에 화면을 걷어낸다.
      await tester.pumpScreen(const Scaffold(body: Text('다른 화면')));
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });
}
