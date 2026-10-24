import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';
import 'package:shiftly/features/tasks/data/memory_task_repository.dart';
import 'package:shiftly/features/tasks/domain/personal_task.dart';
import 'package:shiftly/features/tasks/domain/task_reminders.dart';
import 'package:shiftly/features/tasks/presentation/tasks_screen.dart';
import 'package:shiftly/features/tasks/presentation/widgets/task_additional_times.dart';
import 'package:shiftly/features/tasks/presentation/widgets/task_editor.dart';

const scope = FeatureSessionScope(
  userId: 'preview-user',
  workspaceId: 'workspace',
  membershipId: 'membership',
  timezone: 'Africa/Cairo',
  role: WorkspaceRole.employee,
);

class RecordingReminders extends NoTaskReminders {
  final calls = <String>[];
  @override
  Future<TaskReminderPermission> permission(
    String userId, {
    bool request = false,
  }) async => TaskReminderPermission.exact;
  @override
  Future<List<PersonalTask>> replace(
    String userId,
    List<PersonalTask> tasks, {
    bool preserveExisting = false,
  }) async {
    calls.add('schedule');
    return tasks;
  }

  @override
  Future<void> clear() async {
    calls.add('clear');
  }

  @override
  Future<String?> installationId() async => 'installation';
}

class RecordingRepository extends MemoryTaskRepository {
  final registrations = <List<PersonalTask>>[];
  @override
  Future<void> register(String installationId, List<PersonalTask> tasks) async {
    registrations.add(tasks);
  }
}

class DelayedTasks extends MemoryTaskRepository {
  final pending = Completer<TaskPage>();
  @override
  Future<TaskPage> list({required bool completed, required int page}) =>
      pending.future;
}

class UnavailableRegistrationRepository extends MemoryTaskRepository {
  int attempts = 0;
  @override
  Future<void> register(String installationId, List<PersonalTask> tasks) async {
    attempts++;
    throw StateError('Registration unavailable');
  }
}

class CapturingTaskRepository extends MemoryTaskRepository {
  bool updated = false;
  DateTime? updatedDueAt;
  @override
  Future<void> update(
    PersonalTask task, {
    String? title,
    String? description,
    DateTime? dueAt,
    bool? completed,
    int? durationMinutes,
    bool? remindDayBefore,
    bool? remindHourBefore,
    List<DateTime>? additionalDueAts,
  }) async {
    updated = true;
    updatedDueAt = dueAt;
  }
}

void main() {
  for (final day in [false, true]) {
    for (final hour in [false, true]) {
      testWidgets('task dialog saves day=$day and hour=$hour independently', (
        tester,
      ) async {
        final tasks = TasksCubit(
          MemoryTaskRepository(),
          const NoTaskReminders(),
        );
        await tasks.bindSession(scope);
        await tester.pumpWidget(
          BlocProvider.value(
            value: tasks,
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const TasksScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, 'Options');
        for (final entry in {
          'task-remind-day': day,
          'task-remind-hour': hour,
        }.entries) {
          final finder = find.byKey(Key(entry.key));
          await tester.ensureVisible(finder);
          if (tester.widget<SwitchListTile>(finder).value != entry.value) {
            await tester.tap(finder);
            await tester.pumpAndSettle();
          }
        }
        await tester.ensureVisible(find.text('Save task'));
        await tester.tap(find.text('Save task'));
        await tester.pumpAndSettle();
        expect(tasks.state.items.single.remindDayBefore, day);
        expect(tasks.state.items.single.remindHourBefore, hour);
        await tester.pumpWidget(const SizedBox());
        await tasks.close();
      });
    }
  }
  test('replenishes the alarm window when an event passes without a task revision change', () async {
    final repo = RecordingRepository(), reminders = RecordingReminders();
    await repo.create(
      workspaceId: 'workspace',
      title: 'Report',
      description: '',
      dueAt: DateTime.utc(2090, 1, 3, 10),
      durationMinutes: 5,
      remindDayBefore: true,
    );
    var now = DateTime.utc(2090, 1, 1);
    final cubit = TasksCubit(repo, reminders, clock: () => now);
    await cubit.bindSession(scope);
    final first = reminders.calls.where((c) => c == 'schedule').length;
    await cubit.syncReminders();
    expect(reminders.calls.where((c) => c == 'schedule'), hasLength(first));
    now = DateTime.utc(2090, 1, 2, 10, 1);
    await cubit.syncReminders();
    expect(reminders.calls.where((c) => c == 'schedule'), hasLength(first + 1));
    await cubit.close();
  });
  test(
    'server registration failure still schedules native alarms and retries',
    () async {
      final repo = UnavailableRegistrationRepository();
      final reminders = RecordingReminders();
      await repo.create(
        workspaceId: 'workspace',
        title: 'Reminder',
        description: '',
        dueAt: DateTime.utc(2090),
      );
      final cubit = TasksCubit(repo, reminders);
      await cubit.bindSession(scope);
      expect(reminders.calls, contains('schedule'));
      expect(cubit.state.reminderError, isTrue);
      final firstAttempts = repo.attempts;
      await cubit.syncReminders();
      expect(repo.attempts, greaterThan(firstAttempts));
      await cubit.close();
    },
  );

  testWidgets('editing an overdue task preserves its exact existing instant', (
    tester,
  ) async {
    final repo = CapturingTaskRepository();
    final cubit = TasksCubit(repo, const NoTaskReminders());
    await cubit.bindSession(scope);
    final task = PersonalTask(
      id: 'task',
      ownerId: scope.userId,
      workspaceId: scope.workspaceId,
      title: 'Overdue task',
      description: '',
      dueAt: DateTime.utc(2000, 1, 1, 10, 30, 45, 123),
      revision: 1,
      completed: false,
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: TaskEditor(task: task)),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'Edited title');
    await tester.ensureVisible(find.text('Save task'));
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    expect(repo.updated, isTrue);
    expect(repo.updatedDueAt, isNull);
    expect(find.text('Choose a future date and time.'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });

  test('task deadlines preserve timezone offsets and completion status', () {
    final task = PersonalTask.fromJson({
      'id': 'task',
      'ownerId': 'owner',
      'workspaceId': 'workspace',
      'title': 'Title',
      'description': 'Details',
      'dueAt': '2090-01-01T12:00:00+02:00',
      'revision': 2,
      'status': 'OPEN',
    });
    expect(task.dueAt, DateTime.utc(2090, 1, 1, 10));
    expect(task.completed, isFalse);
    expect(
      () => PersonalTask.fromJson({'status': 'unexpected'}),
      throwsFormatException,
    );
  });
  test(
    'create, edit, complete, reopen and delete update canonical task state',
    () async {
      final repo = MemoryTaskRepository(),
          cubit = TasksCubit(MemoryTaskRepository(), const NoTaskReminders());
      final tasks = TasksCubit(repo, const NoTaskReminders());
      await tasks.bindSession(scope);
      final due = DateTime.utc(2090, 1, 1, 10);
      expect(
        await tasks.save(title: ' First ', description: 'Details', dueAt: due),
        isTrue,
      );
      expect(tasks.state.items.single.title, 'First');
      var task = tasks.state.items.single;
      expect(
        await tasks.save(
          task: task,
          title: 'Edited',
          description: 'New details',
          dueAt: due,
        ),
        isTrue,
      );
      task = tasks.state.items.single;
      expect(task.title, 'Edited');
      await tasks.toggle(task);
      expect(tasks.state.items, isEmpty);
      await tasks.load(completed: true, page: 1);
      expect(tasks.state.items.single.completed, isTrue);
      await tasks.toggle(tasks.state.items.single);
      await tasks.load(completed: false, page: 1);
      await tasks.remove(tasks.state.items.single);
      expect(tasks.state.total, 0);
      await tasks.close();
      await cubit.close();
    },
  );
  test('clears server acknowledgements before replacing local alarms and acknowledges only success', () async {
    final repo = RecordingRepository(), reminders = RecordingReminders();
    await repo.create(
      workspaceId: 'workspace',
      title: 'Title',
      description: '',
      dueAt: DateTime.utc(2090),
    );
    final cubit = TasksCubit(repo, reminders);
    await cubit.bindSession(scope);
    expect(repo.registrations.first, isEmpty);
    expect(repo.registrations.last.single.title, 'Title');
    expect(reminders.calls, contains('schedule'));
    await cubit.bindSession(null);
    await cubit.syncReminders();
    expect(reminders.calls.last, 'clear');
    await cubit.close();
  });
  test('ignores late account data after sign out', () async {
    final repo = DelayedTasks(),
        cubit = TasksCubit(DelayedTasks(), const NoTaskReminders());
    final tasks = TasksCubit(repo, const NoTaskReminders());
    final loading = tasks.bindSession(scope);
    await tasks.bindSession(null);
    repo.pending.complete(const TaskPage([], 40));
    await loading;
    expect(tasks.state.total, 0);
    expect(tasks.scope, isNull);
    await tasks.close();
    await cubit.close();
  });
  test(
    'never resolves notification taps for another signed-in owner',
    () async {
      final tasks = TasksCubit(MemoryTaskRepository(), const NoTaskReminders());
      await tasks.bindSession(scope);
      expect(await tasks.resolveTap('another-user', 'task'), isNull);
      await tasks.close();
    },
  );
  for (final locale in ['en', 'ar']) {
    for (final width in [390.0, 1280.0]) {
      testWidgets('task editor and cards work at $width in $locale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final tasks = TasksCubit(
          MemoryTaskRepository(),
          const NoTaskReminders(),
        );
        await tasks.bindSession(scope);
        await tester.pumpWidget(
          BlocProvider.value(
            value: tasks,
            child: MaterialApp(
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const TasksScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).first,
          locale == 'ar' ? 'مهمة تجريبية' : 'Test task',
        );
        await tester.enterText(find.byType(TextFormField).last, 'Task details');
        final timePicker = find.byKey(const Key('task-time-picker'));
        await tester.ensureVisible(timePicker);
        await tester.tap(timePicker);
        await tester.pumpAndSettle();
        final confirmTime = find.text(
          locale == 'ar' ? 'تأكيد الوقت' : 'Confirm time',
        );
        expect(confirmTime, findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(confirmTime);
        await tester.pumpAndSettle();
        for (var i = 0; i < 2; i++) {
          final addWeek = find.byKey(const Key('add-task-week'));
          await tester.ensureVisible(addWeek);
          await tester.tap(addWeek);
          await tester.pumpAndSettle();
        }
        expect(
          tester
              .widget<TaskAdditionalTimes>(find.byType(TaskAdditionalTimes))
              .dates,
          hasLength(2),
        );
        await tester.ensureVisible(
          find.text(locale == 'ar' ? 'حفظ المهمة' : 'Save task'),
        );
        await tester.tap(
          find.text(locale == 'ar' ? 'حفظ المهمة' : 'Save task'),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(locale == 'ar' ? 'مهمة تجريبية' : 'Test task'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        final saved = tasks.state.items.single;
        expect(saved.additionalDueAts, hasLength(2));
        expect(saved.additionalDueAts.first.hour, saved.dueAt.hour);
        expect(saved.additionalDueAts.first.minute, saved.dueAt.minute);
        expect(
          saved.additionalDueAts.last,
          DateTime(
            saved.dueAt.year,
            saved.dueAt.month,
            saved.dueAt.day + 14,
            saved.dueAt.hour,
            saved.dueAt.minute,
          ),
        );
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        expect(tasks.state.items, isEmpty);
        await tester.pumpWidget(const SizedBox());
        await tasks.close();
      });
    }
  }
}
