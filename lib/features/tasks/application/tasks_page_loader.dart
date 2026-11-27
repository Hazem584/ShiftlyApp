import 'package:shiftly/core/error/api_error_parser.dart';

import '../domain/task_repository.dart';
import 'tasks_state.dart';

Future<void> loadTasksPageIntoState({
  required TaskRepository repository,
  required TasksState Function() getState,
  required void Function(TasksState) emitState,
  required bool Function() isValidRequest,
  required Future<void> Function({bool? completed, int? page}) reloadPage,
  bool? completed,
  int? page,
}) async {
  final current = getState();
  final changed =
      (completed != null && completed != current.completed) ||
      (page != null && page != current.page);
  emitState(
    current.copy(
      loading: true,
      completed: completed,
      page: page,
      items: changed ? [] : null,
    ),
  );
  final selected = getState().completed, selectedPage = getState().page;
  try {
    final result = await repository.list(
      completed: selected,
      page: selectedPage,
    );
    if (!isValidRequest()) return;
    if (result.items.isEmpty &&
        selectedPage > 1 &&
        result.total <= (selectedPage - 1) * 30) {
      await reloadPage(page: ((result.total - 1) ~/ 30 + 1).clamp(1, 100000));
      return;
    }
    int? otherTotal;
    try {
      otherTotal = (await repository.list(completed: !selected, page: 1)).total;
    } catch (_) {}
    if (!isValidRequest()) return;
    emitState(
      getState().copy(
        items: result.items,
        total: result.total,
        loading: false,
        totalsAvailable: otherTotal != null,
        openTotal: selected ? otherTotal : result.total,
        doneTotal: selected ? result.total : otherTotal,
      ),
    );
  } catch (error) {
    if (isValidRequest()) {
      emitState(
        getState().copy(
          loading: false,
          error: ApiErrorParser.parse(error).message,
        ),
      );
    }
  }
}
