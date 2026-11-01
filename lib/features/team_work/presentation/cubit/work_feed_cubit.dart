import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

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

class WorkFeedCubit<T> extends Cubit<WorkFeedState<T>> {
  WorkFeedCubit(this.loader) : super(WorkFeedState<T>());
  final Future<WorkPage<T>> Function(int page) loader;
  int _revision = 0;
  Future<void> load({bool more = false}) async {
    if (more && (state.loadingMore || state.loading || !state.hasMore)) return;
    final revision = ++_revision;
    final previous = state;
    final page = more ? previous.page + 1 : 1;
    emit(
      WorkFeedState(
        items: previous.items,
        total: previous.total,
        page: previous.page,
        loading: !more,
        loadingMore: more,
        busyId: previous.busyId,
      ),
    );
    try {
      final result = await loader(page);
      if (isClosed || revision != _revision) return;
      emit(
        WorkFeedState(
          items: List.unmodifiable([
            if (more) ...previous.items,
            ...result.items,
          ]),
          total: result.total,
          page: page,
          busyId: state.busyId,
          notice: result.notice,
        ),
      );
    } catch (error) {
      if (!isClosed && revision == _revision) {
        emit(
          WorkFeedState(
            items: previous.items,
            total: previous.total,
            page: previous.page,
            busyId: state.busyId,
            error: ApiErrorParser.parse(error).message,
          ),
        );
      }
    }
  }

  Future<bool> mutate(String id, Future<void> Function() operation) async {
    if (state.busyId != null) return false;
    emit(
      WorkFeedState(
        items: state.items,
        total: state.total,
        page: state.page,
        busyId: id,
      ),
    );
    try {
      await operation();
      if (isClosed) return false;
      emit(
        WorkFeedState(items: state.items, total: state.total, page: state.page),
      );
      await load();
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          WorkFeedState(
            items: state.items,
            total: state.total,
            page: state.page,
            error: ApiErrorParser.parse(error).message,
          ),
        );
      }
      return false;
    }
  }
}
