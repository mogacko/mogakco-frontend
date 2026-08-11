import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock_delay.dart';
import 'mock_failure.dart';

/// 목록을 어디까지 받아 뒀는지.
///
/// 받아 둔 항목을 들고 있지 않고 개수만 센다. 목록을 통째로 들고 있으면
/// 좋아요나 참여를 누를 때마다 원본이 바뀌어 페이지가 처음으로 되돌아간다 —
/// 읽던 자리를 잃는다.
typedef PageState = ({
  int loaded,
  bool isLoading,
  bool isLoadingMore,
  Object? error,
});

/// 한 번에 받아오는 개수.
///
/// 서버가 정하는 값이라 붙으면 응답을 따라간다. 지금은 목업이라 여기서 정한다.
const pageSize = 5;

/// 목록을 나눠 받는 세 곳(글·모각코·행사)이 같이 쓰는 부분.
///
/// 서버가 붙으면 [fetch] 안이 실제 호출로 바뀐다. 세는 방식과 화면이 보는
/// 모양은 그대로다.
mixin PagingNotifier on Notifier<PageState> {
  /// 지금 필터에 걸린 전체 개수.
  int get total;

  /// 이번 build 가 몇 번째인지.
  ///
  /// 필터를 바꾸면 build 가 다시 돌면서 앞서 띄운 요청이 아직 날고 있다.
  /// 늦게 도착한 옛 응답이 새 상태를 덮어쓰지 않도록 세대를 견준다.
  int _generation = 0;

  /// build 에서 부른다. 첫 쪽을 받기 시작하면서 로딩 상태를 돌려준다.
  PageState begin() {
    final generation = ++_generation;
    Future<void>.microtask(() => _loadFirst(generation));
    return (loaded: 0, isLoading: true, isLoadingMore: false, error: null);
  }

  /// 서버 왕복을 흉내 낸다. 붙으면 여기가 실제 호출이 된다.
  Future<void> fetch() async {
    await Future<void>.delayed(mockNetworkDelay);
    if (ref.read(mockFailureProvider)) throw const MockNetworkFailure();
  }

  Future<void> _loadFirst(int generation) async {
    try {
      await fetch();
      if (generation != _generation || !ref.mounted) return;
      state = (
        loaded: pageSize,
        isLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } catch (error) {
      if (generation != _generation || !ref.mounted) return;
      state = (
        loaded: 0,
        isLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }

  /// 처음부터 다시. 실패 화면의 '다시 시도'와 당겨서 새로고침이 부른다.
  Future<void> reload() async {
    final generation = ++_generation;
    state = (loaded: 0, isLoading: true, isLoadingMore: false, error: null);
    await _loadFirst(generation);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.loaded >= total) return;

    final generation = _generation;
    state = (
      loaded: state.loaded,
      isLoading: false,
      isLoadingMore: true,
      error: null,
    );

    try {
      await fetch();
      if (generation != _generation || !ref.mounted) return;
      state = (
        loaded: state.loaded + pageSize,
        isLoading: false,
        isLoadingMore: false,
        error: null,
      );
    } catch (error) {
      if (generation != _generation || !ref.mounted) return;
      // 이미 받아 둔 것은 그대로 둔다. 뒤가 실패했다고 앞까지 지우면
      // 읽던 것이 통째로 사라진다.
      state = (
        loaded: state.loaded,
        isLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }
}
