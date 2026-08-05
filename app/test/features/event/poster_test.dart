import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/event/domain/poster.dart';
import 'package:mogacko/features/event/presentation/widgets/poster_image.dart';
import 'package:mogacko/features/event/presentation/widgets/poster_picker_field.dart';

import '../../helpers/pump_app.dart';

/// 1x1 투명 PNG. 디코드만 되면 되므로 가장 작은 것을 쓴다.
final _pngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

void main() {
  group('포스터', () {
    testWidgets('서버가 준 그림은 주소로 받아온다', (tester) async {
      await tester.pumpScreen(
        const Scaffold(
          body: PosterImage(poster: RemotePoster('https://example.com/a.png')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(Image).evaluate().single.widget, isA<Image>());
    });

    testWidgets('기기에서 고른 그림은 바이트로 그린다', (tester) async {
      await tester.pumpScreen(
        Scaffold(body: PosterImage(poster: LocalPoster(_pngBytes))),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      // 경로가 아니라 바이트여야 웹과 앱에서 같은 방법으로 그려진다.
      expect(image.image, isA<MemoryImage>());
    });
  });

  group('포스터 고르기', () {
    testWidgets('처음에는 고르라는 자리만 있다', (tester) async {
      await tester.pumpScreen(
        Scaffold(
          body: SingleChildScrollView(
            child: PosterPickerField(poster: null, onChanged: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('포스터 고르기'), findsOneWidget);
      expect(find.byType(PosterImage), findsNothing);
      // 없어도 올릴 수 있어야 한다. 필수로 두면 그림 만들 시간이 없다는
      // 이유로 행사가 안 올라온다.
      expect(find.text('선택'), findsOneWidget);
    });

    testWidgets('고르고 나면 미리보기와 바꾸기·빼기가 뜬다', (tester) async {
      await tester.pumpScreen(
        Scaffold(
          body: SingleChildScrollView(
            child: PosterPickerField(
              poster: LocalPoster(_pngBytes),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PosterImage), findsOneWidget);
      expect(find.text('다른 그림'), findsOneWidget);
      expect(find.text('빼기'), findsOneWidget);
      expect(find.text('포스터 고르기'), findsNothing);
    });

    testWidgets('미리보기는 상세와 같은 4:3 이다', (tester) async {
      await tester.pumpScreen(
        Scaffold(
          body: SingleChildScrollView(
            child: PosterPickerField(
              poster: LocalPoster(_pngBytes),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 여기서 멀쩡해 보이던 글자가 올리고 나서 잘려 있으면 다시 만들어야 한다.
      final ratio = tester.widget<AspectRatio>(
        find.ancestor(
          of: find.byType(PosterImage),
          matching: find.byType(AspectRatio),
        ),
      );
      expect(ratio.aspectRatio, 4 / 3);
    });

    testWidgets('빼면 다시 고르는 자리로 돌아간다', (tester) async {
      Poster? current = LocalPoster(_pngBytes);

      await tester.pumpScreen(
        StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: SingleChildScrollView(
              child: PosterPickerField(
                poster: current,
                onChanged: (poster) => setState(() => current = poster),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 시험대는 800x600 이라 4:3 미리보기가 화면을 다 채운다. 버튼이 아래로
      // 밀려 있어 끌어오지 않으면 누른 자리가 허공이다.
      await tester.ensureVisible(find.text('빼기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('빼기'));
      await tester.pumpAndSettle();

      expect(current, isNull);
      expect(find.text('포스터 고르기'), findsOneWidget);
    });
  });
}
