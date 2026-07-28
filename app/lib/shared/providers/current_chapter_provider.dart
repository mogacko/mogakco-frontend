import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chapter.dart';

/// 지금 보고 있는 지역.
///
/// 가입할 때 고른 지역이 기본값이 된다. 서버 연동 전이라 부산으로 시작한다.
class CurrentChapter extends Notifier<Chapter> {
  @override
  Chapter build() => Chapter.busan;

  void change(Chapter chapter) {
    // 아직 열지 않은 지역은 고를 수 없다.
    if (!chapter.isOpen) return;
    state = chapter;
  }
}

final currentChapterProvider = NotifierProvider<CurrentChapter, Chapter>(
  CurrentChapter.new,
);
