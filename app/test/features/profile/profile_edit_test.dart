import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/comment/presentation/comment_provider.dart';
import 'package:mogacko/features/community/presentation/post_provider.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/auth/presentation/session_provider.dart';
import 'package:mogacko/features/profile/presentation/profile_edit_screen.dart';
import 'package:mogacko/features/profile/presentation/profile_provider.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('프로필 수정', () {
    Finder save() => find.widgetWithText(FilledButton, '저장');

    /// 순서로 잡으면 분야·스택·관심분야의 입력칸과 섞인다.
    Finder nickname() => find.byKey(const Key('nickname-input'));
    Finder bio() => find.byKey(const Key('bio-input'));

    testWidgets('지금 값이 채워진 채로 열린다', (tester) async {
      final container = await tester.pumpScreen(const ProfileEditScreen());
      await tester.pumpAndSettle();

      final profile = container.read(profileProvider);
      expect(find.text(profile.nickname), findsWidgets);
      expect(find.text(profile.bio!), findsOneWidget);
      expect(find.text(profile.affiliation!), findsOneWidget);
    });

    testWidgets('닉네임이 짧으면 저장할 수 없다', (tester) async {
      await tester.pumpScreen(const ProfileEditScreen());
      await tester.pumpAndSettle();

      await tester.enterText(nickname(), 'a');
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(save()).onPressed, isNull);
      expect(find.text('2자 이상 입력해 주세요'), findsOneWidget);
    });

    testWidgets('쓸 수 없는 글자는 막는다', (tester) async {
      await tester.pumpScreen(const ProfileEditScreen());
      await tester.pumpAndSettle();

      await tester.enterText(nickname(), 'evan!!');
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(save()).onPressed, isNull);
      expect(find.textContaining('밑줄만'), findsOneWidget);
    });

    testWidgets('저장하면 프로필이 바뀐다', (tester) async {
      final container = await tester.pumpScreen(const ProfileEditScreen());
      await tester.pumpAndSettle();

      await tester.enterText(nickname(), 'evan2');
      await tester.pumpAndSettle();
      await tester.tap(save());
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).nickname, 'evan2');
    });

    testWidgets('닉네임을 바꾸면 내 글·모임·댓글도 따라온다', (tester) async {
      final container = await tester.pumpScreen(const ProfileEditScreen());
      await tester.pumpAndSettle();

      final before = container.read(profileProvider).nickname;
      final myPosts = container
          .read(postFeedProvider)
          .where((post) => post.author == before)
          .length;
      expect(myPosts, greaterThan(0));

      await tester.enterText(nickname(), 'evan2');
      await tester.pumpAndSettle();
      await tester.tap(save());
      await tester.pumpAndSettle();

      // 목업은 이름 문자열이 곧 사람이다. 여기서 안 맞춰주면 내가 쓴 글이
      // 남의 글이 되고 작성글 수가 0으로 떨어진다.
      expect(
        container.read(postFeedProvider).where((p) => p.author == before),
        isEmpty,
      );
      expect(
        container.read(postFeedProvider).where((p) => p.author == 'evan2').length,
        myPosts,
      );
      expect(
        container.read(meetupListProvider).where((m) => m.host == before),
        isEmpty,
      );
      expect(
        container
            .read(commentListProvider)
            .where((c) => c.isMine && c.author != 'evan2'),
        isEmpty,
      );
      // 새로 쓰는 글이 옛 이름으로 올라가지 않도록 세션도 함께 간다.
      expect(container.read(sessionProvider)?.nickname, 'evan2');
    });

    testWidgets('분야를 비우면 저장할 수 없다', (tester) async {
      await tester.pumpScreen(const ProfileEditScreen());
      await tester.pumpAndSettle();

      // 분야 알약의 X. 스택·관심분야에도 같은 아이콘이 있어 분야 칸 안으로
      // 좁힌다.
      final remove = find.descendant(
        of: find.byKey(const Key('field-input')),
        matching: find.byIcon(CupertinoIcons.xmark),
      );
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pumpAndSettle();

      // 가입 때 받는 필수 항목이다. 수정으로 지워지면 가입으로는 만들 수 없는
      // 프로필이 생긴다.
      expect(tester.widget<FilledButton>(save()).onPressed, isNull);
    });

    testWidgets('자기소개를 비우면 지워진다', (tester) async {
      final container = await tester.pumpScreen(const ProfileEditScreen());
      await tester.pumpAndSettle();

      await tester.enterText(bio(), '');
      await tester.pumpAndSettle();
      await tester.tap(save());
      await tester.pumpAndSettle();

      expect(container.read(profileProvider).bio, isNull);
    });

    testWidgets('닉네임이 그대로면 아무것도 옮기지 않는다', (tester) async {
      final container = await tester.pumpScreen(const ProfileEditScreen());
      await tester.pumpAndSettle();

      final before = container.read(postFeedProvider);

      await tester.tap(save());
      await tester.pumpAndSettle();

      // 이름이 안 바뀌었는데 목록을 새로 만들면 스크롤 위치와 애니메이션이
      // 통째로 다시 시작한다.
      expect(identical(container.read(postFeedProvider), before), isTrue);
    });
  });
}
