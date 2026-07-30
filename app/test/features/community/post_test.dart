import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/community/domain/post.dart';
import 'package:mogacko/shared/domain/chapter.dart';

void main() {
  group('Post', () {
    Post make({String body = '본문', int likeCount = 3, bool isLiked = false}) {
      return Post(
        id: 'p',
        chapter: Chapter.busan,
        board: PostBoard.talk,
        category: PostCategory.free,
        title: '제목',
        body: body,
        author: 'evan',
        createdAt: DateTime(2026, 7, 27, 10),
        likeCount: likeCount,
        isLiked: isLiked,
      );
    }

    test('좋아요를 누르면 수가 함께 오른다', () {
      final liked = make(likeCount: 3).toggleLike();

      expect(liked.isLiked, isTrue);
      expect(liked.likeCount, 4);
    });

    test('좋아요를 되누르면 원래대로 돌아온다', () {
      final back = make(likeCount: 3).toggleLike().toggleLike();

      expect(back.isLiked, isFalse);
      expect(back.likeCount, 3);
    });

    test('목록에 세울 앞부분은 줄바꿈을 한 칸으로 눕힌다', () {
      // 그대로 두면 첫 문단만 보이고 두 줄이 차기 전에 잘린다.
      final post = make(body: '첫 줄\n\n둘째 줄   셋째');

      expect(post.excerpt, '첫 줄 둘째 줄 셋째');
    });

    test('요약을 따로 두지 않아 목록과 상세가 어긋날 수 없다', () {
      final post = make(body: '  본문 전체  ');

      expect(post.excerpt, '본문 전체');
      expect(post.body, '  본문 전체  ');
    });
  });
}
