import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/tasks/application/task_widget_sync.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';
import 'package:shiftly/features/tasks/data/memory_task_repository.dart';
import 'package:shiftly/features/tasks/data/native_task_home_widget.dart';
import 'package:shiftly/features/tasks/domain/personal_task.dart';
import 'package:shiftly/features/tasks/domain/task_home_widget.dart';
import 'package:shiftly/features/tasks/domain/task_reminders.dart';

import 'tasks_feature_test.dart' show scope;

PersonalTask task(
  String id,
  DateTime due, {
  String owner = 'preview-user',
  bool done = false,
}) => PersonalTask(
  id: id,
  ownerId: owner,
  workspaceId: 'workspace',
  title: id,
  description: 'Private description',
  dueAt: due,
  revision: 1,
  completed: done,
);

class WidgetRecorder implements TaskHomeWidget {
  @override
  bool get isSupported => false;
  @override
  Future<bool> requestPin() async => false;
  final owners = <String>[];
  final pages = <TaskPage>[];
  int clears = 0;
  Completer<void>? gate;
  @override
  Future<void> clear() async {
    clears++;
    owners.clear();
    pages.clear();
  }

  @override
  Future<void> publish(String owner, TaskPage page, DateTime now) async {
    await gate?.future;
    owners.add(owner);
    pages.add(page);
  }
}

class WidgetRepository extends MemoryTaskRepository {
  Completer<TaskPage>? gate;
  TaskPage result = const TaskPage([], 0);
  @override
  Future<TaskPage> list({required bool completed, required int page}) async =>
      gate == null ? result : await gate!.future;
}

class SequencedWidgetRepository extends MemoryTaskRepository {
  final requests = <Completer<TaskPage>>[];
  @override
  Future<TaskPage> list({required bool completed, required int page}) {
    final result = Completer<TaskPage>();
    requests.add(result);
    return result.future;
  }
}

void main() {
  test(
    'an older refresh cannot restore a task after a newer response',
    () async {
      final repository = SequencedWidgetRepository();
      final widget = WidgetRecorder();
      final sync = TaskWidgetSync(repository, widget);
      await sync.bind('u');
      final older = sync.refresh();
      final newer = sync.refresh();
      repository.requests[1].complete(const TaskPage([], 0));
      await newer;
      repository.requests[0].complete(
        TaskPage([task('old', DateTime.now(), owner: 'u')], 1),
      );
      await older;
      expect(widget.pages.map((p) => p.total), [0]);
      await sync.close();
    },
  );

  test('snapshot keeps overdue tasks, filters owners and completed, uses exact total', () {
    final now = DateTime.utc(2026, 10, 31, 12);
    final snapshot = NativeTaskHomeWidget.snapshot(
      'preview-user',
      TaskPage([
        task('later', now.add(const Duration(hours: 2))),
        task('overdue', now.subtract(const Duration(hours: 1))),
        task('done', now, done: true),
        task('another-user', now, owner: 'other'),
        task('soon', now.add(const Duration(minutes: 5))),
        task('fourth', now.add(const Duration(hours: 3))),
      ], 45),
      now,
    );
    expect(snapshot['total'], 45);
    final rows = snapshot['tasks'] as List;
    expect(rows.map((r) => (r as Map)['id']), ['overdue', 'soon', 'later']);
    expect(rows.every((r) => !(r as Map).containsKey('description')), isTrue);
    expect(
      snapshot['expiresAt'],
      now.add(const Duration(hours: 24)).millisecondsSinceEpoch,
    );
  });

  test('running task counts down to its end and additional dates use next occurrence', () {
    final now = DateTime.utc(2026, 10, 31, 12);
    final running = PersonalTask(
      id: 'running',
      ownerId: 'u',
      workspaceId: 'w',
      title: 'Running',
      description: '',
      dueAt: now.subtract(const Duration(minutes: 10)),
      durationMinutes: 60,
      revision: 1,
      completed: false,
    );
    final repeating = PersonalTask(
      id: 'repeat',
      ownerId: 'u',
      workspaceId: 'w',
      title: 'Repeat',
      description: '',
      dueAt: now.subtract(const Duration(days: 1)),
      additionalDueAts: [now.add(const Duration(hours: 2))],
      revision: 1,
      completed: false,
    );
    final rows =
        NativeTaskHomeWidget.snapshot(
              'u',
              TaskPage([repeating, running], 2),
              now,
            )['tasks']
            as List;
    expect(
      (rows.first as Map)['endsAt'],
      now.add(const Duration(minutes: 50)).millisecondsSinceEpoch,
    );
    expect(
      (rows.last as Map)['dueAt'],
      now.add(const Duration(hours: 2)).millisecondsSinceEpoch,
    );
  });

  test(
    'logout drops a delayed fetch before it reaches native storage',
    () async {
      final repository = WidgetRepository()..gate = Completer<TaskPage>();
      final widget = WidgetRecorder();
      final sync = TaskWidgetSync(repository, widget);
      await sync.bind('old');
      final pending = sync.refresh();
      await sync.bind(null);
      repository.gate!.complete(
        TaskPage([task('secret', DateTime.now(), owner: 'old')], 1),
      );
      await pending;
      expect(widget.owners, isEmpty);
      expect(widget.clears, 2);
      await sync.close();
    },
  );

  test('logout clears after a native publish already in progress', () async {
    final repository = WidgetRepository();
    final widget = WidgetRecorder()..gate = Completer<void>();
    final sync = TaskWidgetSync(repository, widget);
    await sync.bind('old');
    final pending = sync.refresh();
    await Future<void>.delayed(Duration.zero);
    final logout = sync.bind(null);
    widget.gate!.complete();
    await Future.wait([pending, logout]);
    expect(widget.owners, isEmpty);
    await sync.close();
  });

  test(
    'new account can refresh while an old account request is still pending',
    () async {
      final repository = WidgetRepository()..gate = Completer<TaskPage>();
      final oldGate = repository.gate!;
      final widget = WidgetRecorder();
      final sync = TaskWidgetSync(repository, widget);
      await sync.bind('old');
      final pending = sync.refresh();
      await sync.bind('new');
      repository.gate = null;
      repository.result = TaskPage([
        task('new-task', DateTime.now(), owner: 'new'),
      ], 1);
      await sync.refresh();
      oldGate.complete(
        TaskPage([task('old-task', DateTime.now(), owner: 'old')], 1),
      );
      await pending;
      expect(widget.owners, ['new']);
      await sync.close();
    },
  );

  test('task completion refreshes widget without requiring notification permission', () async {
    final repository = MemoryTaskRepository();
    final widget = WidgetRecorder();
    final cubit = TasksCubit(
      repository,
      const NoTaskReminders(),
      homeWidget: widget,
    );
    await cubit.bindSession(scope);
    await cubit.save(
      title: 'Finish report',
      description: '',
      dueAt: DateTime.now().add(const Duration(hours: 1)),
    );
    expect(widget.pages.last.total, 1);
    final saved = (await repository.list(
      completed: false,
      page: 1,
    )).items.single;
    await cubit.toggle(saved);
    expect(widget.pages.last.total, 0);
    await cubit.bindSession(null);
    expect(widget.owners, isEmpty);
    await cubit.close();
  });
}
