import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

/// 한 번에 다 받지 않고 나눠 받는 목록.
///
/// 서버가 커서를 쓰든 페이지 번호를 쓰든 화면은 이 모양만 본다. 어느 쪽으로
/// 정해지든 목록 화면은 손대지 않고 받아오는 함수만 바뀐다.
class Paged<T> {
  const Paged({
    this.items = const [],
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<T> items;

  /// 더 받을 게 남았는지. 서버가 빈 쪽을 주면 false 가 된다.
  final bool hasMore;

  /// 첫 쪽을 받는 중. 아직 보여줄 게 아무것도 없다.
  final bool isLoading;

  final bool isLoadingMore;

  /// 다음 쪽을 받다 실패한 것. 이미 받아 둔 [items] 는 그대로 둔다 —
  /// 뒤가 실패했다고 앞까지 지우면 읽던 것이 통째로 사라진다.
  final Object? error;

  /// 처음 받는 중이라 화면이 텅 빈 상태.
  bool get isFirstLoad => isLoading && items.isEmpty;

  /// 처음부터 실패해서 보여줄 게 없는 상태.
  ///
  /// 뒤쪽을 받다 실패한 것과 다르다. 그쪽은 이미 읽던 게 남아 있어 목록
  /// 아래에 '다시 시도'만 붙이면 되지만, 여기는 화면 전체가 비어 있다.
  bool get failedFirst => error != null && items.isEmpty;

  bool get isEmpty => items.isEmpty && !hasMore && !isLoading && error == null;

  Paged<T> loading() =>
      Paged(items: items, hasMore: hasMore, isLoadingMore: true);

  Paged<T> failed(Object error) =>
      Paged(items: items, hasMore: hasMore, error: error);

  Paged<T> appended(List<T> next, {required bool hasMore}) =>
      Paged(items: [...items, ...next], hasMore: hasMore);

  /// 처음부터 다시 받았다.
  Paged<T> replaced(List<T> next, {required bool hasMore}) =>
      Paged(items: next, hasMore: hasMore);
}

/// 끝에 가까워지면 다음 쪽을 부른다.
///
/// 마지막 항목이 보일 때까지 기다리지 않고 한 화면쯤 앞에서 미리 부른다.
/// 바닥에 닿고 나서 부르면 스피너를 보는 시간이 그대로 드러난다.
class LoadMoreOnScroll extends StatelessWidget {
  const LoadMoreOnScroll({
    super.key,
    required this.onLoadMore,
    required this.canLoadMore,
    required this.child,
  });

  final VoidCallback onLoadMore;

  /// 지금 부를 수 있는 상태인지. 이미 받는 중이거나 더 없으면 false.
  final bool canLoadMore;

  final Widget child;

  /// 바닥에서 이만큼 남았을 때 미리 부른다.
  static const _lead = 600.0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!canLoadMore) return false;
        final metrics = notification.metrics;
        if (metrics.axis != Axis.vertical) return false;
        if (metrics.pixels >= metrics.maxScrollExtent - _lead) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}

/// 목록 맨 아래에 붙는 줄.
///
/// 받는 중인지, 실패했는지, 다 봤는지를 여기 하나로 말한다. 화면마다 따로
/// 두면 같은 상태를 서로 다르게 보여주게 된다.
class PagedFooter extends StatelessWidget {
  const PagedFooter({super.key, required this.state, required this.onRetry});

  final Paged<Object?> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Text('더 불러오지 못했어요', style: context.texts.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: SizedBox(
            width: AppSize.iconSm,
            height: AppSize.iconSm,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // 더 없을 때는 아무 말도 하지 않는다. '마지막입니다' 같은 줄은 목록이
    // 짧을 때 오히려 허전함을 키운다.
    if (state.hasMore || state.items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: colors.border,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
