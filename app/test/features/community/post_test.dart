import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/features/community/domain/post.dart';
import 'package:mogacko/shared/domain/chapter.dart';

void main() {
  group('Post', () {
    Post make({int likeCount = 3, int commentCount = 2, bool isLiked = false}) {
      return Post(
        id: 'p',
        chapter: Chapter.busan,
        board: PostBoard.talk,
        category: PostCategory.free,
        title: '제목',
        excerpt: '본문',
        author: 'evan',
        createdAt: DateTime(2026, 7, 27, 10),
        likeCount: likeCount,
        commentCount: commentCount,
        isLiked: isLiked,
      );
    }

    test('댓글을 좋아요보다 무겁게 센다', () {
      expect(make(likeCount: 3, commentCount: 2).engagement, 3 + 2 * 2);
    });

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
  });
}
