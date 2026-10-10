import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/app/session_feature_coordinator.dart';
import 'package:shiftly/core/localization/language_cubit.dart';
import 'package:shiftly/core/localization/language_preference_store.dart';
import 'package:shiftly/core/localization/memory_language_store.dart';
import 'package:shiftly/core/offline/read_sync_cubit.dart';
import 'package:shiftly/core/offline/saved_read_store.dart';
import 'package:shiftly/core/routing/app_router.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/memory_theme_store.dart';
import 'package:shiftly/core/theme/theme_cubit.dart';
import 'package:shiftly/core/theme/theme_preference_store.dart';
import 'package:shiftly/features/attendance/data/api_attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/data/mock_attendance_repository.dart';
import 'package:shiftly/features/attendance/data/mock_leave_request_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/chat/data/chat_image_gallery.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/mock_chat_repository.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/fixed_shifts/data/preview_fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/invitations/data/mock_invitation_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/manager_performance/data/memory_manager_intent_storage.dart';
import 'package:shiftly/features/manager_performance/data/unavailable_manager_points_repository.dart';
import 'package:shiftly/features/manager_performance/domain/repositories/manager_intent_storage.dart';
import 'package:shiftly/features/manager_performance/domain/repositories/manager_points_repository.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/notifications/data/mock_notification_repository.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_device_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_preference_store.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_cubit.dart';
import 'package:shiftly/features/onboarding/data/memory_onboarding_storage.dart';
import 'package:shiftly/features/onboarding/domain/repositories/onboarding_storage.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shiftly/features/points/data/mock_points_repository.dart';
import 'package:shiftly/features/points/data/redemption_intent_storage.dart';
import 'package:shiftly/features/points/domain/repositories/points_repository.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';
import 'package:shiftly/features/profile/data/mock_profile_repository.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_repository.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/reports/data/api_attendance_report_repository.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_cubit.dart';
import 'package:shiftly/features/shifts/data/mock_shift_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_cubit.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_cubit.dart';
import 'package:shiftly/features/workspaces/data/mock_workspace_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

import 'app_dependencies.dart';
import 'session_router_refresh.dart';
import 'session_scope_factories.dart';

class AppComposition {
  late final LanguageCubit languageCubit;
  late final ThemeCubit themeCubit;
  late final ReadSyncCubit readSyncCubit;
  late final EmployeeRepository employees;
  late final InvitationRepository invitations;
  late final WorkspaceRepository workspaces;
  late final GoRouter router;
  late final OnboardingCubit onboardingCubit;
  late final DashboardCubit dashboardCubit;
  late final EmployeesCubit employeesCubit;
  late final WorkspacesCubit workspacesCubit;
  late final LeaveRequestRepository leaveRequests;
  late final ProfileRepository profile;
  late final ProfileImagePicker profileImagePicker;
  late final LeaveRequestsCubit leaveRequestsCubit;
  late final EmployeeLeaveRequestsCubit employeeLeaveRequestsCubit;
  late final ProfileCubit profileCubit;
  late final ShiftRepository shifts;
  late final AttendanceRepository attendance;
  late final ManagerShiftsCubit managerShiftsCubit;
  late final EmployeeShiftsCubit employeeShiftsCubit;
  late final ManagerAttendanceCubit managerAttendanceCubit;
  late final AttendanceCalendarCubit attendanceCalendarCubit;
  late final AttendanceReportsCubit attendanceReportsCubit;
  late final EmployeeAttendanceCubit employeeAttendanceCubit;
  late final NotificationRepository notifications;
  late final NotificationsCubit notificationsCubit;
  late final ChatRepository chat;
  late final ChatRealtime chatRealtime;
  late final ChatGroupsCubit chatGroupsCubit;
  late final FixedShiftRepository fixedShifts;
  late final ManagerTemplatesCubit managerTemplatesCubit;
  late final FlexibleAttendanceCubit flexibleAttendanceCubit;
  late final PointsRepository points;
  late final PointsCubit pointsCubit;
  late final ManagerPerformanceCubit managerPerformanceCubit;
  late final SessionCoordinator? sessionCoordinator;
  StreamSubscription<Object?>? sessionSubscription;
  SessionRouterRefresh? sessionRefresh;
  late final SessionFeatureCoordinator featureCoordinator;
  PushNotificationsCubit? pushNotifications;
  PushDeviceRepository? pushDevices;

  AppComposition(
    this.dependencies, {
    required this.isMounted,
    required this.onOpened,
    required this.onForeground,
  }) {
    languageCubit = LanguageCubit(
      dependencies.languageStore ??
          registered<LanguagePreferenceStore>() ??
          MemoryLanguageStore(),
    );
    themeCubit = ThemeCubit(
      registered<ThemePreferenceStore>() ?? MemoryThemeStore(),
    );
    readSyncCubit =
        registered<ReadSyncCubit>() ?? ReadSyncCubit(SavedReadStore());
    featureCoordinator = SessionFeatureCoordinator(applySession);
    sessionCoordinator =
        dependencies.sessionCoordinator ?? registered<SessionCoordinator>();
    employees =
        dependencies.employeeRepository ??
        registered<EmployeeRepository>() ??
        MockEmployeeRepository();
    invitations =
        dependencies.invitationRepository ??
        registered<InvitationRepository>() ??
        MockInvitationRepository();
    workspaces =
        dependencies.workspaceRepository ??
        registered<WorkspaceRepository>() ??
        MockWorkspaceRepository();
    final dashboard =
        dependencies.dashboardRepository ??
        registered<DashboardRepository>() ??
        (dependencies.preview
            ? MockDashboardRepository(
                employeeRepository: MockEmployeeRepository(),
              )
            : throw StateError(
                'Authenticated apps must inject DashboardRepository.',
              ));
    onboardingCubit = OnboardingCubit(
      dependencies.onboardingStorage ??
          registered<OnboardingStorage>() ??
          MemoryOnboardingStorage(),
    );
    unawaited(onboardingCubit.restore());
    sessionRefresh = sessionCoordinator == null
        ? null
        : SessionRouterRefresh(sessionCoordinator!, onboardingCubit);
    router =
        dependencies.router ??
        createAppRouter(
          sessionCoordinator: sessionCoordinator,
          onboarding: onboardingCubit,
          refreshListenable: sessionRefresh,
        );
    leaveRequests =
        dependencies.leaveRequestRepository ??
        registered<LeaveRequestRepository>() ??
        MockLeaveRequestRepository();
    profile =
        dependencies.profileRepository ??
        registered<ProfileRepository>() ??
        MockProfileRepository();
    profileImagePicker =
        dependencies.profileImagePicker ??
        registered<ProfileImagePicker>() ??
        DeviceProfileImagePicker();
    shifts =
        dependencies.shiftRepository ??
        registered<ShiftRepository>() ??
        const MockShiftRepository();
    attendance =
        dependencies.attendanceRepository ??
        registered<AttendanceRepository>() ??
        const MockAttendanceRepository();
    fixedShifts =
        dependencies.fixedShiftRepository ??
        registered<FixedShiftRepository>() ??
        (dependencies.preview
            ? const PreviewFixedShiftRepository()
            : throw StateError(
                'Authenticated apps must inject FixedShiftRepository.',
              ));
    points =
        dependencies.pointsRepository ??
        registered<PointsRepository>() ??
        (dependencies.preview
            ? const MockPointsRepository()
            : throw StateError(
                'Authenticated apps must inject PointsRepository.',
              ));
    pointsCubit =
        registered<PointsCubit>() ??
        PointsCubit(points, intentStorage: MemoryRedemptionIntentStorage());
    managerPerformanceCubit = ManagerPerformanceCubit(
      registered<ManagerPointsRepository>() ??
          const UnavailableManagerPointsRepository(),
      registered<ManagerIntentStorage>() ?? MemoryManagerIntentStorage(),
      onChanged: () {
        dashboardCubit.invalidate();
        attendanceCalendarCubit.invalidate();
        unawaited(pointsCubit.load(refresh: true));
      },
    );
    notifications =
        dependencies.notificationRepository ??
        registered<NotificationRepository>() ??
        (dependencies.preview
            ? MockNotificationRepository()
            : throw StateError(
                'Authenticated apps must inject NotificationRepository.',
              ));
    dashboardCubit = registered<DashboardCubit>() ?? DashboardCubit(dashboard);
    attendanceCalendarCubit = AttendanceCalendarCubit(
      registered<AttendanceCalendarRepository>() ??
          ApiAttendanceCalendarRepository(shifts, attendance, leaveRequests),
    );
    attendanceReportsCubit = AttendanceReportsCubit(
      ApiAttendanceReportRepository(attendance, employees),
    );
    employeesCubit = EmployeesCubit(
      employees,
      invitations: invitations,
      onDashboardChanged: invalidateDashboardAndCalendar,
    );
    workspacesCubit = WorkspacesCubit(
      workspaces,
      invitations,
      onMembershipChanged: (workspaceId, expectedUserId) async =>
          await sessionCoordinator?.refreshMemberships(
            preferredWorkspaceId: workspaceId,
            expectedUserId: expectedUserId,
          ) ??
          const MembershipRefreshResult.failed(),
    );
    leaveRequestsCubit = LeaveRequestsCubit(
      leaveRequests,
      onDashboardChanged: invalidateDashboardAndCalendar,
    );
    employeeLeaveRequestsCubit = EmployeeLeaveRequestsCubit(
      leaveRequests,
      onDashboardChanged: invalidateDashboardAndCalendar,
    );
    profileCubit = ProfileCubit(
      profile,
      onProfileChanged: sessionCoordinator?.synchronizeProfile,
    );
    managerShiftsCubit = ManagerShiftsCubit(
      shifts,
      onDashboardChanged: invalidateDashboardAndCalendar,
    );
    managerAttendanceCubit = ManagerAttendanceCubit(
      attendance,
      onDashboardChanged: invalidateDashboardAndCalendar,
    );
    employeeAttendanceCubit = EmployeeAttendanceCubit(attendance);
    managerTemplatesCubit =
        registered<ManagerTemplatesCubit>() ??
        ManagerTemplatesCubit(fixedShifts);
    flexibleAttendanceCubit = FlexibleAttendanceCubit(
      fixedShifts,
      onAttendanceChanged: () async {
        await employeeAttendanceCubit.load(refresh: true);
        invalidateDashboardAndCalendar();
        await notificationsCubit.refreshUnreadCount();
      },
    );
    employeeShiftsCubit = EmployeeShiftsCubit(
      shifts,
      attendance,
      onAttendanceChanged: () => employeeAttendanceCubit.load(refresh: true),
      onDashboardChanged: invalidateDashboardAndCalendar,
    );
    notificationsCubit =
        registered<NotificationsCubit>() ?? NotificationsCubit(notifications);
    final locator = dependencies.locator;
    if (locator?.isRegistered<PushMessaging>() == true) {
      pushDevices = locator!<PushDeviceRepository>();
      pushNotifications = PushNotificationsCubit(
        locator<PushMessaging>(),
        pushDevices!,
        locator<PushPreferenceStore>(),
        onOpened: (notice) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isMounted()) unawaited(onOpened(notice));
          });
          WidgetsBinding.instance.scheduleFrame();
        },
        onForeground: onForeground,
      );
    }
    chat =
        dependencies.chatRepository ??
        registered<ChatRepository>() ??
        const MockChatRepository();
    chatRealtime =
        dependencies.chatRealtime ??
        registered<ChatRealtime>() ??
        const NoopChatRealtime();
    chatGroupsCubit =
        registered<ChatGroupsCubit>() ??
        ChatGroupsCubit(chat, gallery: ChatImageGallery());
    final coordinator = sessionCoordinator;
    if (coordinator == null) {
      profileCubit.load();
      employeesCubit.load();
      const previewScope = FeatureSessionScope(
        userId: 'preview-user',
        workspaceId: 'preview-workspace',
        membershipId: 'preview-membership',
        timezone: 'Etc/UTC',
        role: WorkspaceRole.manager,
        workspaceName: 'Shift Lab Preview Workspace',
      );
      managerShiftsCubit.bindSession(previewScope);
      managerAttendanceCubit.bindSession(previewScope);
      attendanceReportsCubit.bindSession(previewScope);
      leaveRequestsCubit.bindSession(previewScope);
      notificationsCubit.bindSession(previewScope);
      dashboardCubit.bindSession(previewScope);
      chatGroupsCubit.bindSession(previewScope);
      managerTemplatesCubit.bindSession(previewScope);
      managerPerformanceCubit.bindSession(previewScope);
    } else {
      sessionSubscription = coordinator.stream.listen(featureCoordinator.bind);
      featureCoordinator.bind(coordinator.state);
    }
  }
  final AppDependencies dependencies;
  final bool Function() isMounted;
  final Future<void> Function(PushNotice) onOpened;
  final Future<void> Function(PushNotice) onForeground;

  void dispose() {
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
    attendanceReportsCubit.close();
    employeeAttendanceCubit.close();
    notificationsCubit.close();
    chatGroupsCubit.close();
    managerTemplatesCubit.close();
    flexibleAttendanceCubit.close();
    pointsCubit.close();
    managerPerformanceCubit.close();
    sessionSubscription?.cancel();
    sessionRefresh?.dispose();
    if (dependencies.locator == null) {
      unawaited(dependencies.sessionCoordinator?.close());
    }
    if (dependencies.router == null) router.dispose();
  }

  void applySession(SessionState state, int generation) {
    readSyncCubit.bind(state);
    profileCubit.bindSession(profileScopeForSession(state));
    employeesCubit.bindSession(employeeScopeForSession(state));
    workspacesCubit.bindUser(state.currentUser?.id);
    final featureScope = featureScopeForSession(state, generation);
    managerShiftsCubit.bindSession(featureScope);
    employeeShiftsCubit.bindSession(featureScope);
    managerAttendanceCubit.bindSession(featureScope);
    attendanceCalendarCubit.bindSession(featureScope);
    attendanceReportsCubit.bindSession(featureScope);
    employeeAttendanceCubit.bindSession(featureScope);
    leaveRequestsCubit.bindSession(featureScope);
    employeeLeaveRequestsCubit.bindSession(featureScope);
    notificationsCubit.bindSession(featureScope);
    pushNotifications?.bindSession(featureScope);
    if (state.status == SessionStatus.unauthenticated ||
        state.status == SessionStatus.sessionExpired) {
      pushNotifications?.signedOut();
    }
    dashboardCubit.bindSession(featureScope);
    chatGroupsCubit.bindSession(featureScope);
    managerTemplatesCubit.bindSession(featureScope);
    flexibleAttendanceCubit.bindSession(featureScope);
    pointsCubit.bindSession(featureScope);
    managerPerformanceCubit.bindSession(featureScope);
  }

  void invalidateDashboardAndCalendar() {
    dashboardCubit.invalidate();
    attendanceCalendarCubit.invalidate();
    attendanceReportsCubit.invalidate();
    unawaited(pointsCubit.load(refresh: true));
    managerPerformanceCubit.invalidate();
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
