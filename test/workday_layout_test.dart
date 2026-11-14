import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_active_attendance_screen.dart';
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
  Future<void> mountAttendance(
    WidgetTester tester,
    HomeAttendance cubit,
    ShiftBreakController breaks,
  ) async {
    await tester.pumpWidget(
      RepositoryProvider.value(
        value: breaks,
        child: BlocProvider<FlexibleAttendanceCubit>.value(
          value: cubit,
          child: MaterialApp(
            theme: AppTheme.darkTheme(),
            home: EmployeeActiveAttendanceScreen(
              timezone: 'Africa/Cairo',
              now: () => now,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'active attendance shows net worked time and allows multiple breaks',
    (tester) async {
      final cubit = HomeAttendance(active());
      final breaks = ShiftBreakController(now: () => now)..bind('owner');
      await mountAttendance(tester, cubit, breaks);
      expect(find.text('02:48:00'), findsOneWidget);
      Future<void> start() async {
        await tester.ensureVisible(
          find.byKey(const Key('employee-break-action')),
        );
        await tester.tap(find.byKey(const Key('employee-break-action')));
        await tester.pumpAndSettle();
        expect(breaks.running, isFalse);
        await tester.tap(find.widgetWithText(FilledButton, 'Start break'));
        await tester.pumpAndSettle();
        expect(breaks.running, isTrue);
      }

      await start();
      expect(find.text('End break'), findsOneWidget);
      await tester.tap(find.byKey(const Key('employee-break-action')));
      await tester.pumpAndSettle();
      expect(find.text('Available break: 1 h'), findsOneWidget);
      expect(breaks.canStart, isTrue);
      await start();
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
      breaks.dispose();
    },
  );
  testWidgets(
    'checkout cancellation preserves attendance and confirmation delegates to the attendance cubit',
    (tester) async {
      final cubit = HomeAttendance(active());
      final breaks = ShiftBreakController(now: () => now)
        ..bind('owner')
        ..restore('shift-1');
      await breaks.start(arabic: false);
      await mountAttendance(tester, cubit, breaks);
      await tester.tap(find.byKey(const Key('employee-check-out')));
      await tester.pumpAndSettle();
      expect(cubit.calls, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(cubit.calls, 0);
      expect(breaks.running, isTrue);
      await tester.tap(find.byKey(const Key('employee-check-out')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-employee-clock-out')));
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
