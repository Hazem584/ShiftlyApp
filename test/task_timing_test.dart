import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/tasks/domain/personal_task.dart';
import 'package:shiftly/features/tasks/domain/task_alarm.dart';
import 'package:shiftly/features/tasks/presentation/widgets/task_countdown.dart';

void main() {
  for (final day in [false, true]) {
    for (final hour in [false, true]) {
      test('day=$day and hour=$hour reminders are independent', () {
        final due = DateTime.utc(2090, 1, 3, 10);
        final task = PersonalTask(
          id: 'options',
          ownerId: 'owner',
          workspaceId: 'workspace',
          title: 'Report',
          description: '',
          dueAt: due,
          revision: 1,
          completed: false,
          remindDayBefore: day,
          remindHourBefore: hour,
        );
        final alarms = TaskAlarm.upcoming(task, DateTime.utc(2090, 1, 1));
        expect(alarms.any((a) => a.kind == TaskAlarmKind.advance), day);
        expect(alarms.any((a) => a.kind == TaskAlarmKind.hour), hour);
        if (hour) {
          expect(
            alarms.singleWhere((a) => a.kind == TaskAlarmKind.hour).at,
            due.subtract(const Duration(hours: 1)),
          );
        }
        expect(
          TaskAlarm.upcoming(
            task,
            due.subtract(const Duration(minutes: 30)),
          ).any((a) => a.kind == TaskAlarmKind.hour),
          isFalse,
        );
      });
    }
  }
  test('a task within its duration is in progress rather than overdue', () {
    final started = DateTime.now().subtract(const Duration(minutes: 2));
    PersonalTask running(int minutes) => PersonalTask(
      id: 'running',
      ownerId: 'owner',
      workspaceId: 'workspace',
      title: 'Report',
      description: '',
      dueAt: started,
      revision: 1,
      completed: false,
      durationMinutes: minutes,
    );
    expect(running(5).overdue, isFalse);
    expect(running(1).overdue, isTrue);
  });
  final due = DateTime.utc(2090, 1, 3, 10);
  PersonalTask task({bool completed = false}) => PersonalTask(
    id: 'task',
    ownerId: 'owner',
    workspaceId: 'workspace',
    title: 'Report',
    description: '',
    dueAt: due,
    revision: 1,
    completed: completed,
    durationMinutes: 5,
    remindDayBefore: true,
  );

  test(
    'reminders target exactly 24 hours before, due time and duration end',
    () {
      final alarms = TaskAlarm.upcoming(task(), DateTime.utc(2090, 1, 1));
      expect(alarms.map((a) => a.at), [
        due,
        due.subtract(const Duration(hours: 24)),
        due.add(const Duration(minutes: 5)),
      ]);
      expect(alarms.map((a) => a.key).toSet(), hasLength(3));
      expect(
        TaskAlarm.upcoming(task(completed: true), DateTime.utc(2090)),
        isEmpty,
      );
      final afterStart = TaskAlarm.upcoming(
        task(),
        due.add(const Duration(minutes: 1)),
      );
      expect(afterStart.single.kind, TaskAlarmKind.end);
      expect(
        TaskAlarm.upcoming(task(), due.add(const Duration(minutes: 6))),
        isEmpty,
      );
    },
  );

  for (final language in ['en', 'ar']) {
    testWidgets(
      'countdown restores the wall clock and transitions in $language',
      (tester) async {
        var now = due.subtract(const Duration(days: 1, seconds: 5));
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: TaskCountdown(task: task(), now: () => now),
            ),
          ),
        );
        expect(find.text('00:00:05'), findsOneWidget);
        expect(
          find.text(language == 'ar' ? 'فاضل على المهمة' : 'Starts in'),
          findsOneWidget,
        );
        now = due.add(const Duration(minutes: 2));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('00:03:00'), findsOneWidget);
        expect(
          find.text(language == 'ar' ? 'باقي من وقت المهمة' : 'Time remaining'),
          findsOneWidget,
        );
        now = due.add(const Duration(minutes: 6));
        await tester.pump(const Duration(seconds: 1));
        expect(
          find.text(language == 'ar' ? 'وقت المهمة انتهى' : 'Task time ended'),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
