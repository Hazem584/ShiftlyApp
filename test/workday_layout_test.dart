import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/shift_session_card.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/work_week_strip.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';
import 'package:shiftly/features/tasks/data/memory_task_repository.dart';
import 'package:shiftly/features/tasks/domain/task_reminders.dart';

import 'support/attendance_test_cubit.dart';

class HomeAttendance extends AttendanceTestCubit {
  HomeAttendance(super.initial);
  int calls = 0;
  @override
  Future<FixedShiftMutationResult> clockOut() async {
    calls++;
    return FixedShiftMutationResult.success;
  }
}

void main() {
  testWidgets(
    'week calendar keeps all seven dates across the Cairo DST change',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: const Scaffold(body: WorkWeekStrip(date: '2026-10-26')),
        ),
      );
      for (final day in ['26', '27', '28', '29', '30', '31', '1']) {
        expect(find.text(day), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
  final now = DateTime.utc(2026, 10, 26, 10, 48);
  FlexibleAttendanceState active() => FlexibleAttendanceState(
    loading: false,
    current: FlexibleAttendance(
      id: 'shift-1',
      workspaceId: 'workspace',
      employeeMembershipId: 'member',
      source: AttendanceSource.template,
      classification: AttendanceClassification.onTime,
      clockInAt: DateTime.utc(2026, 10, 26, 8),
      scheduledStartAt: DateTime.utc(2026, 10, 26, 8),
      scheduledEndAt: DateTime.utc(2026, 10, 26, 16),
      minutesLate: 0,
      createdAt: now,
      updatedAt: now,
    ),
  );
  testWidgets(
    'home shows canonical worked and remaining time and a local break',
    (tester) async {
      final breaks = ShiftBreakController(now: () => now)..bind('owner');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShiftSessionCard(
                state: active(),
                timezone: 'Africa/Cairo',
                breaks: breaks,
                now: () => now,
              ),
            ),
          ),
        ),
      );
      expect(find.text('5h 12m'), findsOneWidget);
      expect(find.text('Worked 2h 48m'), findsOneWidget);
      await tester.tap(find.byKey(const Key('start-shift-break')));
      await tester.pumpAndSettle();
      expect(find.text('End break'), findsOneWidget);
      expect(breaks.running, isTrue);
      await tester.tap(find.byKey(const Key('start-shift-break')));
      await tester.pumpAndSettle();
      expect(find.text('Break used'), findsOneWidget);
      expect(breaks.used, isTrue);
      await tester.pumpWidget(const SizedBox());
      breaks.dispose();
    },
  );
  testWidgets(
    'clock out requires confirmation and delegates to canonical attendance',
    (tester) async {
      final cubit = HomeAttendance(active());
      final breaks = ShiftBreakController(now: () => now)
        ..bind('owner')
        ..restore('shift-1');
      await breaks.start(arabic: false);
      await tester.pumpWidget(
        BlocProvider<FlexibleAttendanceCubit>.value(
          value: cubit,
          child: MaterialApp(
            theme: AppTheme.darkTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: ShiftSessionCard(
                  state: active(),
                  timezone: 'Africa/Cairo',
                  breaks: breaks,
                  now: () => now,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('home-clock-out')));
      await tester.pumpAndSettle();
      expect(cubit.calls, 0);
      await tester.tap(find.byKey(const Key('confirm-home-clock-out')));
      await tester.pumpAndSettle();
      expect(cubit.calls, 1);
      expect(breaks.running, isFalse);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
      breaks.dispose();
    },
  );
  test(
    'task progress uses both complete totals rather than the visible page',
    () async {
      final repo = MemoryTaskRepository();
      for (var i = 0; i < 70; i++) {
        await repo.create(
          workspaceId: 'workspace',
          title: 'Task $i',
          description: '',
          dueAt: now,
        );
      }
      final first = await repo.list(completed: false, page: 1);
      for (final task in first.items.take(5)) {
        await repo.update(task, completed: true);
      }
      final cubit = TasksCubit(repo, const NoTaskReminders());
      await cubit.bindSession(
        const FeatureSessionScope(
          userId: 'preview-user',
          workspaceId: 'workspace',
          membershipId: 'member',
          timezone: 'Africa/Cairo',
          role: WorkspaceRole.employee,
        ),
      );
      expect(cubit.state.items.length, 30);
      expect(cubit.state.openTotal, 65);
      expect(cubit.state.doneTotal, 5);
      expect(cubit.state.totalsAvailable, isTrue);
      await cubit.toggle(cubit.state.items.first);
      expect(cubit.state.openTotal, 64);
      expect(cubit.state.doneTotal, 6);
      await cubit.close();
    },
  );
}
