import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/session_provider.dart';
import '../domain/chapter.dart';

/// 지금 보고 있는 지역.
///
/// 가입할 때 고른 지역에서 시작한다. 잠깐 다른 지부를 구경하러 바꿀 수 있지만
/// 계정에 붙은 지역([Session.chapter])은 그대로다.
class CurrentChapter extends Notifier<Chapter> {
  @override
  Chapter build() => ref.watch(sessionProvider)?.chapter ?? Chapter.seoul;

  void change(Chapter chapter) {
    // 아직 열지 않은 지역은 고를 수 없다.
    if (!chapter.isOpen) return;
    state = chapter;
  }
}

final currentChapterProvider = NotifierProvider<CurrentChapter, Chapter>(
  CurrentChapter.new,
);
