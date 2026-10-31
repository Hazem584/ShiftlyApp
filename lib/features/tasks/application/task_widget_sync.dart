import '../domain/task_home_widget.dart';
import '../domain/task_repository.dart';

/// Serializes native writes so an old account cannot overwrite a new snapshot.
class TaskWidgetSync {
  TaskWidgetSync(this.repository, this.widget);
  final TaskRepository repository;
  final TaskHomeWidget widget;
  int _generation = 0;
  String? _owner;
  int _request = 0;
  Future<void> _writes = Future.value();

  Future<void> bind(String? owner) async {
    _owner = owner;
    _generation++;
    await _write(widget.clear);
  }

  Future<void> _write(Future<void> Function() action) {
    _writes = _writes.then((_) => action()).catchError((Object _) {});
    return _writes;
  }

  Future<void> refresh() async {
    final owner = _owner, generation = _generation;
    if (owner == null) return;
    final request = ++_request;
    try {
      // The ordinary OPEN listing includes overdue tasks and an exact total;
      // the reminder endpoint deliberately excludes some overdue tasks.
      final page = await repository.list(completed: false, page: 1);
      if (generation != _generation || owner != _owner || request != _request) {
        return;
      }
      await _write(() async {
        if (generation != _generation ||
            owner != _owner ||
            request != _request) {
          return;
        }
        await widget.publish(owner, page, DateTime.now());
      });
    } catch (_) {
      // Keep the last successful snapshot while offline; native views expire it.
    }
  }

  Future<void> close() async {
    _generation++;
    await _writes;
  }
}
