import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shiftly/app/app_composition_state.dart';
import 'package:shiftly/app/app_repositories.dart';
import 'package:shiftly/app/session_feature_coordinator.dart';
import 'package:shiftly/app/session_router_refresh.dart';
import 'package:shiftly/core/localization/language_cubit.dart';
import 'package:shiftly/core/localization/language_preference_store.dart';
import 'package:shiftly/core/localization/memory_language_store.dart';
import 'package:shiftly/core/offline/read_sync_cubit.dart';
import 'package:shiftly/core/offline/saved_read_store.dart';
import 'package:shiftly/core/routing/app_router.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/memory_theme_store.dart';
import 'package:shiftly/core/theme/theme_cubit.dart';
import 'package:shiftly/core/theme/theme_preference_store.dart';
import 'package:shiftly/features/attendance/data/api_attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_calendar_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/onboarding/data/memory_onboarding_storage.dart';
import 'package:shiftly/features/onboarding/domain/repositories/onboarding_storage.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shiftly/features/reports/data/api_attendance_report_repository.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_cubit.dart';

void initializeCoreComposition(
  AppCompositionState c,
  T? Function<T extends Object>() registered,
  void Function(SessionState, int) applySession,
) {
  c.languageCubit = LanguageCubit(
    c.dependencies.languageStore ??
        registered<LanguagePreferenceStore>() ??
        MemoryLanguageStore(),
  );
  c.themeCubit = ThemeCubit(
    registered<ThemePreferenceStore>() ?? MemoryThemeStore(),
  );
  c.readSyncCubit =
      registered<ReadSyncCubit>() ?? ReadSyncCubit(SavedReadStore());
  c.featureCoordinator = SessionFeatureCoordinator(applySession);
  c.sessionCoordinator =
      c.dependencies.sessionCoordinator ?? registered<SessionCoordinator>();
  final repos = AppRepositories(c.dependencies, registered);
  c
    ..employees = repos.employees
    ..invitations = repos.invitations
    ..workspaces = repos.workspaces
    ..leaveRequests = repos.leaveRequests
    ..profile = repos.profile
    ..profileImagePicker = repos.profileImagePicker
    ..shifts = repos.shifts
    ..attendance = repos.attendance
    ..fixedShifts = repos.fixedShifts
    ..notifications = repos.notifications
    ..onboardingCubit = OnboardingCubit(
      c.dependencies.onboardingStorage ??
          registered<OnboardingStorage>() ??
          MemoryOnboardingStorage(),
    );
  unawaited(c.onboardingCubit.restore());
  c.sessionRefresh = c.sessionCoordinator == null
      ? null
      : SessionRouterRefresh(c.sessionCoordinator!, c.onboardingCubit);
  c.router =
      c.dependencies.router ??
      createAppRouter(
        sessionCoordinator: c.sessionCoordinator,
        onboarding: c.onboardingCubit,
        refreshListenable: c.sessionRefresh,
      );
  c.dashboardCubit =
      registered<DashboardCubit>() ?? DashboardCubit(repos.dashboard);
  final dio = registered<Dio>();
  c.attendanceCalendarCubit = AttendanceCalendarCubit(
    registered<AttendanceCalendarRepository>() ??
        ApiAttendanceCalendarRepository(
          c.shifts,
          c.attendance,
          c.leaveRequests,
          dio: dio,
        ),
  );
  c.employeeAttendanceCalendarCubit = EmployeeAttendanceCalendarCubit(
    ApiAttendanceCalendarRepository(
      c.shifts,
      c.attendance,
      c.leaveRequests,
      dio: dio,
      employeeOnly: true,
    ),
  );
  c.attendanceReportsCubit = AttendanceReportsCubit(
    ApiAttendanceReportRepository(c.attendance, c.employees),
  );
}
