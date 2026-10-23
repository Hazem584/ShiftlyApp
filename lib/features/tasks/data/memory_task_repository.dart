import 'package:uuid/uuid.dart';

import '../domain/personal_task.dart';
import '../domain/task_repository.dart';

class MemoryTaskRepository implements TaskRepository {
  final _items = <String, PersonalTask>{};
  @override
  Future<TaskPage> list({required bool completed, required int page}) async {
    final items = _items.values.where((t) => t.completed == completed).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return TaskPage(
      items.skip((page - 1) * 30).take(30).toList(),
      items.length,
    );
  }

  @override
  Future<List<PersonalTask>> upcoming() async => _items.values
      .where((t) => !t.completed && t.dueAt.isAfter(DateTime.now()))
      .toList();
  @override
  Future<PersonalTask> get(String id) async => _items[id]!;
  @override
  Future<void> create({
    required String workspaceId,
    required String title,
    required String description,
    required DateTime dueAt,
  }) async {
    final id = const Uuid().v4();
    _items[id] = PersonalTask(
      id: id,
      ownerId: 'preview-user',
      workspaceId: workspaceId,
      title: title,
      description: description,
      dueAt: dueAt,
      revision: 1,
      completed: false,
    );
  }

  @override
  Future<void> update(
    PersonalTask task, {
    String? title,
    String? description,
    DateTime? dueAt,
    bool? completed,
  }) async {
    _items[task.id] = PersonalTask(
      id: task.id,
      ownerId: task.ownerId,
      workspaceId: task.workspaceId,
      title: title ?? task.title,
      description: description ?? task.description,
      dueAt: dueAt ?? task.dueAt,
      revision: task.revision + 1,
      completed: completed ?? task.completed,
    );
  }

  @override
  Future<void> remove(PersonalTask task) async {
    _items.remove(task.id);
  }

  @override
  Future<void> register(
    String installationId,
    List<PersonalTask> scheduled,
  ) async {}
}
