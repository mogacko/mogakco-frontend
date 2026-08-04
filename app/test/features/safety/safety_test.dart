import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/comment/domain/comment.dart';
import 'package:mogacko/features/comment/presentation/comment_provider.dart';
import 'package:mogacko/features/community/presentation/post_provider.dart';
import 'package:mogacko/features/meetup/presentation/meetup_provider.dart';
import 'package:mogacko/features/member/presentation/member_screen.dart';
import 'package:mogacko/features/safety/domain/report.dart';
import 'package:mogacko/features/safety/presentation/blocked_members_screen.dart';
import 'package:mogacko/features/safety/presentation/safety_provider.dart';
import 'package:mogacko/shared/widgets/empty_state.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('신고', () {
    testWidgets('신고한 글은 내 목록에서 사라진다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final target = container.read(chapterPostsProvider).first;
      container
          .read(reportsProvider.notifier)
          .add(
            target: ReportTarget.post,
            targetId: target.id,
            reason: ReportReason.spam,
          );

      // 안 가리면 신고하고도 계속 보여서 신고가 소용없어 보인다.
      expect(
        container.read(chapterPostsProvider).map((post) => post.id),
        isNot(contains(target.id)),
      );
      // 원본에서 지우지는 않는다. 운영진이 판단할 몫이 남아 있다.
      expect(
        container.read(postFeedProvider).map((post) => post.id),
        contains(target.id),
      );
    });

    testWidgets('같은 것을 두 번 신고해도 한 건이다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final reports = container.read(reportsProvider.notifier);
      for (var i = 0; i < 3; i++) {
        reports.add(
          target: ReportTarget.post,
          targetId: 'busan-t1',
          reason: ReportReason.abuse,
        );
      }

      expect(container.read(reportsProvider), hasLength(1));
      expect(reports.has(ReportTarget.post, 'busan-t1'), isTrue);
    });

    testWidgets('신고한 댓글은 개수에서도 빠진다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final comment = container
          .read(commentListProvider)
          .firstWhere((c) => c.targetId == 'busan-t1' && !c.isMine);
      final before = container.read(postCommentCountsProvider)['busan-t1']!;

      container
          .read(reportsProvider.notifier)
          .add(
            target: ReportTarget.comment,
            targetId: comment.id,
            reason: ReportReason.abuse,
          );

      // 목록에 '3'이라 적혀 있는데 열어보니 두 개면 하나가 사라진 것처럼 보인다.
      expect(container.read(postCommentCountsProvider)['busan-t1'], before - 1);
    });

    testWidgets('기타는 직접 적어야 접수된다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      container
          .read(reportsProvider.notifier)
          .add(
            target: ReportTarget.post,
            targetId: 'busan-t2',
            reason: ReportReason.other,
            note: '  ',
          );

      // 공백만 적은 것은 안 적은 것으로 친다.
      expect(container.read(reportsProvider).single.note, isNull);
      expect(ReportReason.other.needsNote, isTrue);
      expect(ReportReason.spam.needsNote, isFalse);
    });
  });

  group('차단', () {
    testWidgets('차단하면 그 사람 글·모임·댓글이 모두 사라진다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      const who = '재현';
      expect(
        container.read(chapterPostsProvider).where((p) => p.author == who),
        isNotEmpty,
      );
      expect(
        container.read(visibleMeetupsProvider).where((m) => m.host == who),
        isNotEmpty,
      );

      container.read(blockedProvider.notifier).block(who);

      // 프로필만 막으면 차단한 이유 — 대개 그 사람 글이 불편해서다 — 가
      // 그대로 남는다.
      expect(
        container.read(chapterPostsProvider).where((p) => p.author == who),
        isEmpty,
      );
      expect(
        container.read(visibleMeetupsProvider).where((m) => m.host == who),
        isEmpty,
      );
      expect(
        container
            .read(commentsOfProvider((target: CommentTarget.post, id: 'busan-t1')))
            .where((c) => c.author == who),
        isEmpty,
      );
    });

    testWidgets('차단을 풀면 돌아온다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      const who = '재현';
      final before = container.read(chapterPostsProvider).length;

      container.read(blockedProvider.notifier).block(who);
      expect(container.read(chapterPostsProvider).length, lessThan(before));

      container.read(blockedProvider.notifier).unblock(who);
      expect(container.read(chapterPostsProvider).length, before);
    });

    testWidgets('차단한 사람의 프로필은 열리지 않는다', (tester) async {
      final container = await tester.pumpScreen(
        const MemberScreen(memberId: '재현'),
      );
      await tester.pumpAndSettle();

      expect(find.text('부산 · 백엔드 · 토스'), findsOneWidget);

      container.read(blockedProvider.notifier).block('재현');
      await tester.pumpAndSettle();

      expect(find.text('차단한 사람이에요'), findsOneWidget);
      expect(find.text('부산 · 백엔드 · 토스'), findsNothing);
    });

    testWidgets('프로필에서 바로 풀 수 있다', (tester) async {
      final container = await tester.pumpScreen(
        const MemberScreen(memberId: '재현'),
      );
      await tester.pumpAndSettle();

      container.read(blockedProvider.notifier).block('재현');
      await tester.pumpAndSettle();

      await tester.tap(find.text('차단 해제'));
      await tester.pumpAndSettle();

      expect(container.read(blockedProvider), isEmpty);
      expect(find.text('부산 · 백엔드 · 토스'), findsOneWidget);
    });

    testWidgets('차단 목록에서 풀 수 있다', (tester) async {
      final container = await tester.pumpScreen(const BlockedMembersScreen());
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);

      container.read(blockedProvider.notifier).block('재현');
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsNothing);
      await tester.tap(find.text('차단 해제'));
      await tester.pumpAndSettle();

      expect(container.read(blockedProvider), isEmpty);
    });

    testWidgets('내 댓글은 내가 나를 차단해도 남는다', (tester) async {
      final container = await tester.pumpScreen(const SizedBox.shrink());
      await tester.pumpAndSettle();

      const thread = (target: CommentTarget.post, id: 'busan-t1');
      final mine = container
          .read(commentsOfProvider(thread))
          .where((c) => c.isMine)
          .length;
      expect(mine, greaterThan(0));

      // 있을 수 없는 일이지만, 걸러내는 규칙이 isMine 을 먼저 보는지 확인한다.
      container.read(blockedProvider.notifier).block('evan');

      expect(
        container.read(commentsOfProvider(thread)).where((c) => c.isMine).length,
        mine,
      );
    });
  });
}
