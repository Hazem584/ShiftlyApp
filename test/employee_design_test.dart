import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_request_form_dialog.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/breaks/application/shift_break_controller.dart';
import 'package:shiftly/features/breaks/domain/shift_break_state.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/employee_dashboard_view.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_active_attendance_screen.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_attendance_gate.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_attendance_hero.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_bottom_navigation.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_page.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_schedule_view.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_shift_details_screen.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/notifications/data/mock_notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';
import 'package:shiftly/features/tasks/data/memory_task_repository.dart';
import 'package:shiftly/features/tasks/domain/task_reminders.dart';

import 'dashboard_fixtures.dart';
import 'support/attendance_test_cubit.dart';

final _date = DateTime.utc(2026, 11, 1, 10, 10, 38);
FlexibleAttendance _attendance({ShiftBreakState? breaks}) => FlexibleAttendance(
  id: 'attendance',
  workspaceId: 'workspace',
  employeeMembershipId: 'employee',
  source: AttendanceSource.template,
  templateName: 'Morning operations',
  clockInAt: _date.subtract(const Duration(hours: 4, minutes: 12, seconds: 38)),
  scheduledStartAt: DateTime.utc(2026, 11, 1, 6),
  scheduledEndAt: DateTime.utc(2026, 11, 1, 14),
  operationalDate: '2026-11-01',
  classification: AttendanceClassification.onTime,
  minutesLate: 0,
  createdAt: _date,
  updatedAt: _date,
  breakState: breaks,
);
EligibleShiftOccurrence _entry({bool eligible = true}) =>
    EligibleShiftOccurrence(
      occurrenceKind: 'BASELINE',
      assignmentId: 'assignment',
      timezone: 'Africa/Cairo',
      eligible: eligible,
      template: ShiftTemplate(
        id: 'template',
        workspaceId: 'workspace',
        name: 'Morning operations',
        color: '#4338CA',
        startMinute: 480,
        endMinute: 960,
        graceMinutes: 10,
        allowedEarlyCheckInMinutes: 15,
        allowedLateCheckInMinutes: 60,
        minimumWorkMinutes: 240,
        active: true,
        overnight: false,
        createdAt: _date,
        updatedAt: _date,
      ),
      operationalDate: '2026-11-01',
      scheduledStartAt: DateTime.utc(2026, 11, 1, 6),
      scheduledEndAt: DateTime.utc(2026, 11, 1, 14),
      checkInWindowStart: DateTime.utc(2026, 11, 1, 5, 45),
      checkInWindowEnd: DateTime.utc(2026, 11, 1, 7),
      classification: AttendanceClassification.onTime,
      lateMinutes: 0,
      recommended: true,
    );
FlexibleAttendanceState _state(EligibleShiftOccurrence e, {Failure? failure}) =>
    FlexibleAttendanceState(
      loading: false,
      failure: failure,
      eligibility: TemplateEligibility(
        workspaceId: 'workspace',
        timezone: 'Africa/Cairo',
        evaluatedAt: DateTime.utc(2026, 11, 1, 6),
        recommended: e,
        eligibleTemplates: [e],
        authorizedOccurrences: [e],
      ),
    );

class _Chat implements ChatRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _DashboardRepo implements DashboardRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Leave implements LeaveRequestRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _CalendarRepository implements AttendanceCalendarRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Calendar extends EmployeeAttendanceCalendarCubit {
  _Calendar(AttendanceCalendarState state) : super(_CalendarRepository()) {
    emit(state);
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  bool arabic = false,
  double width = 390,
  FlexibleAttendanceState? attendance,
  ShiftBreakController? breaks,
  AttendanceCalendarState? calendar,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final font = FontLoader(arabic ? 'Cairo' : 'InterTight')
    ..addFont(
      rootBundle.load(
        arabic
            ? 'assets/fonts/Cairo-Variable.ttf'
            : 'assets/fonts/InterTight-Variable.ttf',
      ),
    );
  await font.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<EmployeeAttendanceCalendarCubit>(
          create: (_) => _Calendar(calendar ?? const AttendanceCalendarState()),
        ),
        BlocProvider<FlexibleAttendanceCubit>(
          create: (_) => AttendanceTestCubit(
            attendance ?? const FlexibleAttendanceState(loading: false),
          ),
        ),
        BlocProvider(create: (_) => DashboardCubit(_DashboardRepo())),
        BlocProvider(
          create: (_) => NotificationsCubit(MockNotificationRepository()),
        ),
        BlocProvider(
          create: (_) =>
              TasksCubit(MemoryTaskRepository(), const NoTaskReminders()),
        ),
        BlocProvider(create: (_) => ChatGroupsCubit(_Chat())),
        BlocProvider(create: (_) => EmployeeLeaveRequestsCubit(_Leave())),
      ],
      child: RepositoryProvider<ShiftBreakController>.value(
        value: breaks ?? ShiftBreakController(now: () => _date),
        child: MaterialApp(
          locale: Locale(arabic ? 'ar' : 'en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: EmployeeDesign.theme(
            dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
            arabic: arabic,
          ),
          home: RepaintBoundary(key: const Key('capture'), child: child),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('EMPLOYEE_PREVIEWS')) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('capture')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.artifacts/employee-design/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets(
    'schedule pages through real future occurrences without creating attendance',
    (tester) async {
      final employee = ShiftEmployeeSummary(
        membershipId: 'employee',
        profileId: 'user',
        role: WorkspaceRole.employee,
        membershipStatus: MembershipStatus.active,
        fullName: 'Omar',
      );
      final shifts = [
        for (final day in [2, 3])
          ShiftRecord(
            id: 'shift-$day',
            workspaceId: 'workspace',
            employeeMembershipId: 'employee',
            createdByMembershipId: 'manager',
            startsAt: DateTime.utc(2026, 11, day, 6),
            endsAt: DateTime.utc(2026, 11, day, 14),
            breakMinutes: 60,
            graceMinutes: 10,
            status: ShiftStatus.scheduled,
            createdAt: _date,
            updatedAt: _date,
            employee: employee,
            notes: day == 2 ? 'Morning operations' : 'Evening support',
          ),
      ];
      await _pump(
        tester,
        EmployeePage(
          title: 'Schedule',
          child: EmployeeScheduleView(
            timezone: 'Africa/Cairo',
            now: () => _date,
          ),
        ),
        attendance: _state(_entry()),
        calendar: AttendanceCalendarState(
          year: 2026,
          month: 11,
          data: AttendanceCalendarMonth(
            year: 2026,
            month: 11,
            timezone: 'Africa/Cairo',
            days: const {},
            scheduledShifts: shifts,
          ),
        ),
      );
      expect(find.textContaining('Mon, Nov 2'), findsOneWidget);
      expect(find.textContaining('Evening support'), findsOneWidget);
      await _capture(tester, 'schedule');
      await tester.tap(find.byTooltip('Next week'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Evening support'), findsNothing);
      expect(find.text('No scheduled shifts in this week.'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous week'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Evening support'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'attendance hero shows net elapsed time rather than a fabricated remaining duration',
    (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: EmployeeAttendanceHero(
              attendance: _attendance(),
              timezone: 'Africa/Cairo',
              now: () => _date,
            ),
          ),
        ),
      );
      expect(find.text('04:12:38'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final (dark, arabic, name) in [
    (false, false, 'home-light'),
    (true, false, 'home-dark'),
    (false, true, 'home-arabic'),
  ]) {
    testWidgets('employee home uses the approved layout: $name', (
      tester,
    ) async {
      final data = employeeDashboard(timezone: 'Africa/Cairo');
      await _pump(
        tester,
        Scaffold(
          body: SafeArea(
            child: EmployeeDashboardView(
              data: data,
              state: DashboardLoaded(data: data),
              now: () => _date,
            ),
          ),
          bottomNavigationBar: EmployeeBottomNavigation(
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
        dark: dark,
        arabic: arabic,
        attendance: FlexibleAttendanceState(
          loading: false,
          current: _attendance(),
        ),
      );
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(find.byKey(const Key('employee-attendance-hero')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, name);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('eligible shift has an explicit check-in confirmation', (
    tester,
  ) async {
    final e = _entry();
    await _pump(
      tester,
      EmployeeShiftDetailsScreen(entry: e, timezone: 'Africa/Cairo'),
      attendance: _state(e),
    );
    expect(find.text('Check in'), findsOneWidget);
    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();
    expect(find.text('Start your shift?'), findsOneWidget);
    expect(find.byKey(const Key('confirm-flexible-clock-in')), findsOneWidget);
  });
  testWidgets('failed or stale eligibility cannot expose check-in', (
    tester,
  ) async {
    final e = _entry();
    await _pump(
      tester,
      EmployeeShiftDetailsScreen(entry: e, timezone: 'Africa/Cairo'),
      attendance: _state(e, failure: const Failure(message: 'Offline')),
    );
    expect(find.text('Check in'), findsNothing);
    expect(find.text('Offline'), findsOneWidget);
  });
  testWidgets(
    'recovery preserves the original request reference and suppresses a new check-in',
    (tester) async {
      final state = FlexibleAttendanceState(
        loading: false,
        recovery: const PendingClockIn(
          userId: 'user',
          workspaceId: 'workspace',
          membershipId: 'employee',
          templateId: 'template',
          clientAttendanceId: 'original-request',
        ),
      );
      await _pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: EmployeeAttendanceGate(
              state: state,
              timezone: 'Africa/Cairo',
            ),
          ),
        ),
        attendance: state,
      );
      expect(find.text('original-request'), findsOneWidget);
      expect(find.text('Check original request'), findsOneWidget);
      expect(find.text('Check in'), findsNothing);
    },
  );
  testWidgets('shift detail fits narrow Arabic screens with larger text', (
    tester,
  ) async {
    final e = _entry();
    await _pump(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: EmployeeShiftDetailsScreen(entry: e, timezone: 'Africa/Cairo'),
      ),
      attendance: _state(e),
      arabic: true,
      width: 320,
    );
    expect(tester.takeException(), isNull);
    await _capture(tester, 'shift-arabic-compact');
  });
  testWidgets('leave is a complete screen with a pinned submission action', (
    tester,
  ) async {
    await _pump(tester, const LeaveRequestFormDialog(timezone: 'Africa/Cairo'));
    expect(find.text('Request time off'), findsOneWidget);
    expect(find.byKey(const Key('submit-leave-request')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'leave-request');
  });
  testWidgets(
    'active attendance retains the break allowance and checkout action',
    (tester) async {
      final policy = ShiftBreakState(
        allowedMinutes: 60,
        consumedSeconds: 1800,
        revision: 2,
        shiftEndsAt: _date.add(const Duration(hours: 4)),
      );
      final breaks = ShiftBreakController(now: () => _date)
        ..bind('test-user')
        ..restore('attendance', policy: policy, arabic: false);
      await _pump(
        tester,
        EmployeeActiveAttendanceScreen(
          timezone: 'Africa/Cairo',
          now: () => _date,
        ),
        attendance: FlexibleAttendanceState(
          loading: false,
          current: _attendance(breaks: policy),
        ),
        breaks: breaks,
      );
      expect(find.byKey(const Key('employee-check-out')), findsOneWidget);
      expect(find.text('Start break'), findsOneWidget);
      expect(find.text('Available break: 30 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _capture(tester, 'active-attendance');
      await tester.pumpWidget(const SizedBox.shrink());
      breaks.dispose();
    },
  );
}
