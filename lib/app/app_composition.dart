import 'dart:async';

import 'package:shiftly/app/app_composition_collaboration_init.dart';
import 'package:shiftly/app/app_composition_core_init.dart';
import 'package:shiftly/app/app_composition_session_binding.dart';
import 'package:shiftly/app/app_composition_state.dart';
import 'package:shiftly/app/app_composition_workforce_init.dart';
import 'package:shiftly/core/session/session_state.dart';

class AppComposition extends AppCompositionState {
  AppComposition(
    super.dependencies, {
    required super.isMounted,
    required super.onOpened,
    required super.onForeground,
  }) {
    initializeCoreComposition(this, registered, applySession);
    initializeWorkforceComposition(
      this,
      registered,
      invalidateDashboardAndCalendar,
    );
    initializeCollaborationAndTasksComposition(this, registered);
    bindInitialOrCoordinatorSession(this);
  }

  void dispose() {
    taskCoordinator.dispose();
    unawaited(breakAttendanceSubscription?.cancel());
    shiftBreaks.dispose();
    unawaited(pushNotifications?.close());
    onboardingCubit.close();
    languageCubit.close();
    themeCubit.close();
    readSyncCubit.close();
    dashboardCubit.close();
    employeesCubit.close();
    workspacesCubit.close();
    leaveRequestsCubit.close();
    employeeLeaveRequestsCubit.close();
    profileCubit.close();
    managerShiftsCubit.close();
    employeeShiftsCubit.close();
    managerAttendanceCubit.close();
    attendanceCalendarCubit.close();
    employeeAttendanceCalendarCubit.close();
    attendanceReportsCubit.close();
    employeeAttendanceCubit.close();
    notificationsCubit.close();
    chatGroupsCubit.close();
    managerTemplatesCubit.close();
    flexibleAttendanceCubit.close();
    sessionSubscription?.cancel();
    sessionRefresh?.dispose();
    if (dependencies.locator == null) {
      unawaited(dependencies.sessionCoordinator?.close());
    }
    if (dependencies.router == null) router.dispose();
  }

  void applySession(SessionState state, int generation) =>
      applyCompositionSession(this, state, generation);

  Future<void> openTaskTap() => taskCoordinator.openPending();

  void invalidateDashboardAndCalendar({bool reports = true}) {
    dashboardCubit.invalidate();
    attendanceCalendarCubit.invalidate();
    employeeAttendanceCalendarCubit.invalidate();
    if (reports) attendanceReportsCubit.invalidate();
  }

  T? registered<T extends Object>() {
    final locator = dependencies.locator;
    if (locator == null) return null;
    if (!locator.isRegistered<T>()) {
      throw StateError('Missing production dependency: $T');
    }
    return locator<T>();
  }
}
