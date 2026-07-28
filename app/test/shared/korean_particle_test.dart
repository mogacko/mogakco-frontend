import 'package:flutter_test/flutter_test.dart';
import 'package:mogacko/shared/domain/chapter.dart';
import 'package:mogacko/shared/utils/korean_particle.dart';

void main() {
  group('KoreanParticle', () {
    test('받침이 있으면 은, 없으면 는', () {
      expect(KoreanParticle.topic('서울'), '은');
      expect(KoreanParticle.topic('부산'), '은');
      expect(KoreanParticle.topic('제주'), '는');
      expect(KoreanParticle.topic('대구'), '는');
    });

    test('이/가, 을/를도 같은 규칙을 따른다', () {
      expect(KoreanParticle.subject('부산'), '이');
      expect(KoreanParticle.subject('제주'), '가');
      expect(KoreanParticle.object('서울'), '을');
      expect(KoreanParticle.object('광주'), '를');
    });

    test('한글이 아니거나 비어 있으면 받침 없는 쪽을 쓴다', () {
      expect(KoreanParticle.topic(''), '는');
      expect(KoreanParticle.topic('Seoul'), '는');
    });

    test('모든 지역명에 조사를 붙일 수 있다', () {
      for (final chapter in Chapter.values) {
        final particle = KoreanParticle.topic(chapter.label);
        expect(['은', '는'], contains(particle), reason: chapter.label);
      }
    });
  });
}
