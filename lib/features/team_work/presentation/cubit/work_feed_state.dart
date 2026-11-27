class WorkFeedState<T> {
  const WorkFeedState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.total = 0,
    this.page = 0,
    this.busyId,
    this.error,
    this.notice,
  });
  final List<T> items;
  final bool loading, loadingMore;
  final int total, page;
  final String? busyId, error;
  final String? notice;
  bool get hasMore => items.length < total;
}
