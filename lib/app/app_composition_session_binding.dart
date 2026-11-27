import 'dart:async';

import 'package:shiftly/app/app_composition_state.dart';
import 'package:shiftly/app/session_scope_factories.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

void bindInitialOrCoordinatorSession(AppCompositionState c) {
  final coordinator = c.sessionCoordinator;
  if (coordinator == null) {
    c.profileCubit.load();
    c.employeesCubit.load();
    const previewScope = FeatureSessionScope(
      userId: 'preview-user',
      workspaceId: 'preview-workspace',
      membershipId: 'preview-membership',
      timezone: 'Etc/UTC',
      role: WorkspaceRole.manager,
      workspaceName: 'Shift Lab Preview Workspace',
    );
    unawaited(c.taskCoordinator.bindSession(previewScope));
    c.managerShiftsCubit.bindSession(previewScope);
    c.managerAttendanceCubit.bindSession(previewScope);
    c.attendanceReportsCubit.bindSession(previewScope);
    c.leaveRequestsCubit.bindSession(previewScope);
    c.notificationsCubit.bindSession(previewScope);
    c.dashboardCubit.bindSession(previewScope);
    c.chatGroupsCubit.bindSession(previewScope);
    c.managerTemplatesCubit.bindSession(previewScope);
  } else {
    c.sessionSubscription = coordinator.stream.listen(
      c.featureCoordinator.bind,
    );
    c.featureCoordinator.bind(coordinator.state);
  }
}

void applyCompositionSession(
  AppCompositionState c,
  SessionState state,
  int generation,
) {
  c.readSyncCubit.bind(state);
  c.profileCubit.bindSession(profileScopeForSession(state));
  c.employeesCubit.bindSession(employeeScopeForSession(state));
  c.workspacesCubit.bindUser(state.currentUser?.id);
  final featureScope = featureScopeForSession(state, generation);
  c.shiftBreaks.bind(featureScope?.userId);
  unawaited(c.taskCoordinator.bindSession(featureScope));
  c.managerShiftsCubit.bindSession(featureScope);
  c.employeeShiftsCubit.bindSession(featureScope);
  c.managerAttendanceCubit.bindSession(featureScope);
  c.attendanceCalendarCubit.bindSession(featureScope);
  c.employeeAttendanceCalendarCubit.bindSession(featureScope);
  c.attendanceReportsCubit.bindSession(featureScope);
  c.employeeAttendanceCubit.bindSession(featureScope);
  c.leaveRequestsCubit.bindSession(featureScope);
  c.employeeLeaveRequestsCubit.bindSession(featureScope);
  c.notificationsCubit.bindSession(featureScope);
  c.pushNotifications?.bindSession(featureScope);
  if (state.status == SessionStatus.unauthenticated ||
      state.status == SessionStatus.sessionExpired) {
    c.pushNotifications?.signedOut();
  }
  c.dashboardCubit.bindSession(featureScope);
  c.chatGroupsCubit.bindSession(featureScope);
  c.managerTemplatesCubit.bindSession(featureScope);
  c.flexibleAttendanceCubit.bindSession(featureScope);
}
