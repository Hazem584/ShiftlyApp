import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/app/app_lifecycle_listener.dart';
import 'package:shiftly/app/session_feature_coordinator.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_cubit.dart';
import 'package:shiftly/core/localization/language_preference_store.dart';
import 'package:shiftly/core/localization/language_settings.dart';
import 'package:shiftly/core/localization/memory_language_store.dart';
import 'package:shiftly/core/routing/app_router.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';
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
import 'package:shiftly/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:shiftly/features/notifications/presentation/utils/notifications_formatters.dart';
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
import 'package:shiftly/features/reports/data/attendance_report_exporter.dart';
import 'package:shiftly/features/reports/data/native_report_file_delivery.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_cubit.dart';
import 'package:shiftly/features/shifts/data/mock_shift_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_cubit.dart';
import 'package:shiftly/features/shifts/presentation/cubit/manager_shifts_cubit.dart';
import 'package:shiftly/features/workspaces/data/mock_workspace_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

class _SessionRouterRefresh extends ChangeNotifier {
  _SessionRouterRefresh(
    SessionCoordinator coordinator,
    OnboardingCubit onboarding,
  ) {
    if (coordinator.state.isAuthenticated) {
      onboarding.bypassForValidatedSession();
    }
    _subscription = coordinator.stream.listen((state) {
      if (state.isAuthenticated) {
        onboarding.bypassForValidatedSession();
      }
      notifyListeners();
    });
    _onboardingSubscription = onboarding.stream.listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<Object?> _subscription;
  late final StreamSubscription<Object?> _onboardingSubscription;

  @override
  void dispose() {
    _subscription.cancel();
    _onboardingSubscription.cancel();
    super.dispose();
  }
}

class AppProviders extends StatefulWidget {
  const AppProviders({
    super.key,
    this.locator,
    this.onboardingStorage,
    this.preview = false,
    this.employeeRepository,
    this.invitationRepository,
    this.workspaceRepository,
    this.dashboardRepository,
    this.leaveRequestRepository,
    this.profileRepository,
    this.profileImagePicker,
    this.router,
    this.sessionCoordinator,
    this.shiftRepository,
    this.attendanceRepository,
    this.notificationRepository,
    this.chatRepository,
    this.chatRealtime,
    this.fixedShiftRepository,
    this.pointsRepository,
    this.languageStore,
  });

  /// Supplying a locator selects authenticated production composition.
  /// Omitting it preserves the explicit preview/test composition API.
  final GetIt? locator;
  final OnboardingStorage? onboardingStorage;
  final bool preview;

  final EmployeeRepository? employeeRepository;
  final InvitationRepository? invitationRepository;
  final WorkspaceRepository? workspaceRepository;
  final DashboardRepository? dashboardRepository;
  final LeaveRequestRepository? leaveRequestRepository;
  final ProfileRepository? profileRepository;
  final ProfileImagePicker? profileImagePicker;
  final GoRouter? router;
  final SessionCoordinator? sessionCoordinator;
  final ShiftRepository? shiftRepository;
  final AttendanceRepository? attendanceRepository;
  final NotificationRepository? notificationRepository;
  final ChatRepository? chatRepository;
  final ChatRealtime? chatRealtime;
  final FixedShiftRepository? fixedShiftRepository;
  final PointsRepository? pointsRepository;
  final LanguagePreferenceStore? languageStore;

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

FeatureSessionScope? _featureScope(SessionState state, int generation) {
  final user = state.currentUser;
  final membership = state.activeMembership;
  if (!state.isAuthenticated || user == null || membership == null) return null;
  if (membership.status != MembershipStatus.active ||
      membership.role == WorkspaceRole.unknown) {
    return null;
  }
  return FeatureSessionScope(
    userId: user.id,
    workspaceId: membership.workspace.id,
    membershipId: membership.id,
    timezone: membership.workspace.timezone,
    role: membership.role,
    workspaceName: membership.workspace.name,
    membershipStatus: membership.status,
    generation: generation,
  );
}

ProfileSessionScope? _profileScope(SessionState state) {
  final user = state.currentUser;
  final membership = state.activeMembership;
  if (!state.isAuthenticated || user == null || membership == null) return null;
  return ProfileSessionScope(
    userId: user.id,
    workspaceId: membership.workspace.id,
  );
}

EmployeeSessionScope? _employeeScope(SessionState state) {
  final user = state.currentUser;
  final membership = state.activeMembership;
  if (!state.isAuthenticated || user == null || membership == null) return null;
  return EmployeeSessionScope(
    userId: user.id,
    workspaceId: membership.workspace.id,
    role: membership.role,
  );
}

class _AppProvidersState extends State<AppProviders> {
  late final LanguageCubit _languageCubit;
  late final EmployeeRepository _employees;
  late final InvitationRepository _invitations;
  late final WorkspaceRepository _workspaces;
  late final GoRouter _router;
  late final OnboardingCubit _onboardingCubit;
  late final DashboardCubit _dashboardCubit;
  late final EmployeesCubit _employeesCubit;
  late final WorkspacesCubit _workspacesCubit;
  late final LeaveRequestRepository _leaveRequests;
  late final ProfileRepository _profile;
  late final ProfileImagePicker _profileImagePicker;
  late final LeaveRequestsCubit _leaveRequestsCubit;
  late final EmployeeLeaveRequestsCubit _employeeLeaveRequestsCubit;
  late final ProfileCubit _profileCubit;
  late final ShiftRepository _shifts;
  late final AttendanceRepository _attendance;
  late final ManagerShiftsCubit _managerShiftsCubit;
  late final EmployeeShiftsCubit _employeeShiftsCubit;
  late final ManagerAttendanceCubit _managerAttendanceCubit;
  late final AttendanceCalendarCubit _attendanceCalendarCubit;
  late final AttendanceReportsCubit _attendanceReportsCubit;
  late final EmployeeAttendanceCubit _employeeAttendanceCubit;
  late final NotificationRepository _notifications;
  late final NotificationsCubit _notificationsCubit;
  late final ChatRepository _chat;
  late final ChatRealtime _chatRealtime;
  late final ChatGroupsCubit _chatGroupsCubit;
  late final FixedShiftRepository _fixedShifts;
  late final ManagerTemplatesCubit _managerTemplatesCubit;
  late final FlexibleAttendanceCubit _flexibleAttendanceCubit;
  late final PointsRepository _points;
  late final PointsCubit _pointsCubit;
  late final ManagerPerformanceCubit _managerPerformanceCubit;
  late final SessionCoordinator? _sessionCoordinator;
  StreamSubscription<Object?>? _sessionSubscription;
  _SessionRouterRefresh? _sessionRefresh;
  late final SessionFeatureCoordinator _featureCoordinator;
  PushNotificationsCubit? _pushNotifications;
  PushDeviceRepository? _pushDevices;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _languageCubit = LanguageCubit(
      widget.languageStore ??
          _registered<LanguagePreferenceStore>() ??
          MemoryLanguageStore(),
    );
    _featureCoordinator = SessionFeatureCoordinator(_applySession);
    _sessionCoordinator =
        widget.sessionCoordinator ?? _registered<SessionCoordinator>();
    _employees =
        widget.employeeRepository ??
        _registered<EmployeeRepository>() ??
        MockEmployeeRepository();
    _invitations =
        widget.invitationRepository ??
        _registered<InvitationRepository>() ??
        MockInvitationRepository();
    _workspaces =
        widget.workspaceRepository ??
        _registered<WorkspaceRepository>() ??
        MockWorkspaceRepository();
    final dashboard =
        widget.dashboardRepository ??
        _registered<DashboardRepository>() ??
        (widget.preview
            ? MockDashboardRepository(
                employeeRepository: MockEmployeeRepository(),
              )
            : throw StateError(
                'Authenticated apps must inject DashboardRepository.',
              ));
    _onboardingCubit = OnboardingCubit(
      widget.onboardingStorage ??
          _registered<OnboardingStorage>() ??
          MemoryOnboardingStorage(),
    );
    unawaited(_onboardingCubit.restore());
    _sessionRefresh = _sessionCoordinator == null
        ? null
        : _SessionRouterRefresh(_sessionCoordinator, _onboardingCubit);
    _router =
        widget.router ??
        createAppRouter(
          sessionCoordinator: _sessionCoordinator,
          onboarding: _onboardingCubit,
          refreshListenable: _sessionRefresh,
        );
    _leaveRequests =
        widget.leaveRequestRepository ??
        _registered<LeaveRequestRepository>() ??
        MockLeaveRequestRepository();
    _profile =
        widget.profileRepository ??
        _registered<ProfileRepository>() ??
        MockProfileRepository();
    _profileImagePicker =
        widget.profileImagePicker ??
        _registered<ProfileImagePicker>() ??
        DeviceProfileImagePicker();
    _shifts =
        widget.shiftRepository ??
        _registered<ShiftRepository>() ??
        const MockShiftRepository();
    _attendance =
        widget.attendanceRepository ??
        _registered<AttendanceRepository>() ??
        const MockAttendanceRepository();
    _fixedShifts =
        widget.fixedShiftRepository ??
        _registered<FixedShiftRepository>() ??
        (widget.preview
            ? const PreviewFixedShiftRepository()
            : throw StateError(
                'Authenticated apps must inject FixedShiftRepository.',
              ));
    _points =
        widget.pointsRepository ??
        _registered<PointsRepository>() ??
        (widget.preview
            ? const MockPointsRepository()
            : throw StateError(
                'Authenticated apps must inject PointsRepository.',
              ));
    _pointsCubit =
        _registered<PointsCubit>() ??
        PointsCubit(_points, intentStorage: MemoryRedemptionIntentStorage());
    _managerPerformanceCubit = ManagerPerformanceCubit(
      _registered<ManagerPointsRepository>() ??
          const UnavailableManagerPointsRepository(),
      _registered<ManagerIntentStorage>() ?? MemoryManagerIntentStorage(),
      onChanged: () {
        _dashboardCubit.invalidate();
        _attendanceCalendarCubit.invalidate();
        unawaited(_pointsCubit.load(refresh: true));
      },
    );
    _notifications =
        widget.notificationRepository ??
        _registered<NotificationRepository>() ??
        (widget.preview
            ? MockNotificationRepository()
            : throw StateError(
                'Authenticated apps must inject NotificationRepository.',
              ));
    _dashboardCubit =
        _registered<DashboardCubit>() ?? DashboardCubit(dashboard);
    _attendanceCalendarCubit = AttendanceCalendarCubit(
      _registered<AttendanceCalendarRepository>() ??
          ApiAttendanceCalendarRepository(_shifts, _attendance, _leaveRequests),
    );
    _attendanceReportsCubit = AttendanceReportsCubit(
      ApiAttendanceReportRepository(_attendance, _employees),
    );
    _employeesCubit = EmployeesCubit(
      _employees,
      invitations: _invitations,
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _workspacesCubit = WorkspacesCubit(
      _workspaces,
      _invitations,
      onMembershipChanged: (workspaceId, expectedUserId) async =>
          await _sessionCoordinator?.refreshMemberships(
            preferredWorkspaceId: workspaceId,
            expectedUserId: expectedUserId,
          ) ??
          const MembershipRefreshResult.failed(),
    );
    _leaveRequestsCubit = LeaveRequestsCubit(
      _leaveRequests,
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _employeeLeaveRequestsCubit = EmployeeLeaveRequestsCubit(
      _leaveRequests,
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _profileCubit = ProfileCubit(
      _profile,
      onProfileChanged: _sessionCoordinator?.synchronizeProfile,
    );
    _managerShiftsCubit = ManagerShiftsCubit(
      _shifts,
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _managerAttendanceCubit = ManagerAttendanceCubit(
      _attendance,
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _employeeAttendanceCubit = EmployeeAttendanceCubit(_attendance);
    _managerTemplatesCubit =
        _registered<ManagerTemplatesCubit>() ??
        ManagerTemplatesCubit(_fixedShifts);
    _flexibleAttendanceCubit = FlexibleAttendanceCubit(
      _fixedShifts,
      onAttendanceChanged: () async {
        await _employeeAttendanceCubit.load(refresh: true);
        _invalidateDashboardAndCalendar();
        await _notificationsCubit.refreshUnreadCount();
      },
    );
    _employeeShiftsCubit = EmployeeShiftsCubit(
      _shifts,
      _attendance,
      onAttendanceChanged: () => _employeeAttendanceCubit.load(refresh: true),
      onDashboardChanged: _invalidateDashboardAndCalendar,
    );
    _notificationsCubit =
        _registered<NotificationsCubit>() ?? NotificationsCubit(_notifications);
    final locator = widget.locator;
    if (locator?.isRegistered<PushMessaging>() == true) {
      _pushDevices = locator!<PushDeviceRepository>();
      _pushNotifications = PushNotificationsCubit(
        locator<PushMessaging>(),
        _pushDevices!,
        locator<PushPreferenceStore>(),
        onOpened: (notice) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_openPushNotice(notice));
          });
          WidgetsBinding.instance.scheduleFrame();
        },
        onForeground: _showPushNotice,
      );
    }
    _chat =
        widget.chatRepository ??
        _registered<ChatRepository>() ??
        const MockChatRepository();
    _chatRealtime =
        widget.chatRealtime ??
        _registered<ChatRealtime>() ??
        const NoopChatRealtime();
    _chatGroupsCubit =
        _registered<ChatGroupsCubit>() ??
        ChatGroupsCubit(_chat, gallery: ChatImageGallery());
    final coordinator = _sessionCoordinator;
    if (coordinator == null) {
      _profileCubit.load();
      _employeesCubit.load();
      const previewScope = FeatureSessionScope(
        userId: 'preview-user',
        workspaceId: 'preview-workspace',
        membershipId: 'preview-membership',
        timezone: 'Etc/UTC',
        role: WorkspaceRole.manager,
        workspaceName: 'Shift Lab Preview Workspace',
      );
      _managerShiftsCubit.bindSession(previewScope);
      _managerAttendanceCubit.bindSession(previewScope);
      _attendanceReportsCubit.bindSession(previewScope);
      _leaveRequestsCubit.bindSession(previewScope);
      _notificationsCubit.bindSession(previewScope);
      _dashboardCubit.bindSession(previewScope);
      _chatGroupsCubit.bindSession(previewScope);
      _managerTemplatesCubit.bindSession(previewScope);
      _managerPerformanceCubit.bindSession(previewScope);
    } else {
      _sessionSubscription = coordinator.stream.listen(
        _featureCoordinator.bind,
      );
      _featureCoordinator.bind(coordinator.state);
    }
  }

  @override
  void dispose() {
    unawaited(_pushNotifications?.close());
    _onboardingCubit.close();
    _languageCubit.close();
    _dashboardCubit.close();
    _employeesCubit.close();
    _workspacesCubit.close();
    _leaveRequestsCubit.close();
    _employeeLeaveRequestsCubit.close();
    _profileCubit.close();
    _managerShiftsCubit.close();
    _employeeShiftsCubit.close();
    _managerAttendanceCubit.close();
    _attendanceCalendarCubit.close();
    _attendanceReportsCubit.close();
    _employeeAttendanceCubit.close();
    _notificationsCubit.close();
    _chatGroupsCubit.close();
    _managerTemplatesCubit.close();
    _flexibleAttendanceCubit.close();
    _pointsCubit.close();
    _managerPerformanceCubit.close();
    _sessionSubscription?.cancel();
    _sessionRefresh?.dispose();
    if (widget.locator == null) unawaited(widget.sessionCoordinator?.close());
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _employees),
        RepositoryProvider.value(value: _invitations),
        RepositoryProvider.value(value: _workspaces),
        RepositoryProvider.value(value: _leaveRequests),
        RepositoryProvider.value(value: _profile),
        RepositoryProvider.value(value: _profileImagePicker),
        RepositoryProvider.value(value: _shifts),
        RepositoryProvider.value(value: _attendance),
        RepositoryProvider<ReportExporter>(
          create: (_) => AttendanceReportExporter(),
        ),
        RepositoryProvider<ReportFileDelivery>(
          create: (_) => NativeReportFileDelivery(),
        ),
        RepositoryProvider.value(value: _notifications),
        RepositoryProvider<ChatRepository>.value(value: _chat),
        RepositoryProvider<ChatRealtime>.value(value: _chatRealtime),
        RepositoryProvider<FixedShiftRepository>.value(value: _fixedShifts),
        RepositoryProvider<PointsRepository>.value(value: _points),
      ],
      child: MultiBlocProvider(
        providers: [
          if (_pushNotifications != null)
            BlocProvider.value(value: _pushNotifications!),
          BlocProvider.value(value: _languageCubit),
          BlocProvider.value(value: _onboardingCubit),
          BlocProvider.value(value: _dashboardCubit),
          BlocProvider.value(value: _employeesCubit),
          BlocProvider.value(value: _workspacesCubit),
          BlocProvider.value(value: _leaveRequestsCubit),
          BlocProvider.value(value: _employeeLeaveRequestsCubit),
          BlocProvider.value(value: _profileCubit),
          BlocProvider.value(value: _managerShiftsCubit),
          BlocProvider.value(value: _employeeShiftsCubit),
          BlocProvider.value(value: _managerAttendanceCubit),
          BlocProvider.value(value: _attendanceCalendarCubit),
          BlocProvider.value(value: _attendanceReportsCubit),
          BlocProvider.value(value: _employeeAttendanceCubit),
          BlocProvider.value(value: _notificationsCubit),
          BlocProvider.value(value: _chatGroupsCubit),
          BlocProvider.value(value: _managerTemplatesCubit),
          BlocProvider.value(value: _flexibleAttendanceCubit),
          BlocProvider.value(value: _pointsCubit),
          BlocProvider.value(value: _managerPerformanceCubit),
        ],
        child: BlocBuilder<LanguageCubit, LanguageSettings>(
          buildWhen: (previous, current) =>
              previous.language != current.language,
          builder: (context, language) => MaterialApp.router(
            locale: language.languageCode == null
                ? null
                : Locale(language.languageCode!),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            title: AppStrings.appName,
            scaffoldMessengerKey: _messengerKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            routerConfig: _router,
          ),
        ),
      ),
    );
    final coordinator = _sessionCoordinator;
    final provided = coordinator == null
        ? app
        : BlocProvider<SessionCoordinator>.value(
            value: coordinator,
            child: app,
          );
    return ShiftlyAppLifecycleListener(
      onResumed: () {
        unawaited(_pushNotifications?.refresh());
        unawaited(_flexibleAttendanceCubit.load(refresh: true));
        unawaited(_notificationsCubit.refreshUnreadCount());
        unawaited(_chatGroupsCubit.refreshUnread());
        _dashboardCubit.invalidate();
      },
      child: provided,
    );
  }

  void _applySession(SessionState state, int generation) {
    _profileCubit.bindSession(_profileScope(state));
    _employeesCubit.bindSession(_employeeScope(state));
    _workspacesCubit.bindUser(state.currentUser?.id);
    final featureScope = _featureScope(state, generation);
    _managerShiftsCubit.bindSession(featureScope);
    _employeeShiftsCubit.bindSession(featureScope);
    _managerAttendanceCubit.bindSession(featureScope);
    _attendanceCalendarCubit.bindSession(featureScope);
    _attendanceReportsCubit.bindSession(featureScope);
    _employeeAttendanceCubit.bindSession(featureScope);
    _leaveRequestsCubit.bindSession(featureScope);
    _employeeLeaveRequestsCubit.bindSession(featureScope);
    _notificationsCubit.bindSession(featureScope);
    _pushNotifications?.bindSession(featureScope);
    if (state.status == SessionStatus.unauthenticated ||
        state.status == SessionStatus.sessionExpired) {
      _pushNotifications?.signedOut();
    }
    _dashboardCubit.bindSession(featureScope);
    _chatGroupsCubit.bindSession(featureScope);
    _managerTemplatesCubit.bindSession(featureScope);
    _flexibleAttendanceCubit.bindSession(featureScope);
    _pointsCubit.bindSession(featureScope);
    _managerPerformanceCubit.bindSession(featureScope);
  }

  void _invalidateDashboardAndCalendar() {
    _dashboardCubit.invalidate();
    _attendanceCalendarCubit.invalidate();
    _attendanceReportsCubit.invalidate();
    unawaited(_pointsCubit.load(refresh: true));
    _managerPerformanceCubit.invalidate();
  }

  void _showPushNotice(PushNotice notice) {
    unawaited(_notificationsCubit.load(refresh: true));
    _dashboardCubit.invalidate();
    final context =
        _router.routerDelegate.navigatorKey.currentState?.overlay?.context;
    if (!mounted || context == null) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(context.tr('You have a new Shiftly update.')),
        action: SnackBarAction(
          label: context.tr('View'),
          onPressed: () => unawaited(_openPushNotice(notice)),
        ),
      ),
    );
  }

  Future<void> _openPushNotice(PushNotice notice) async {
    final scope = _notificationsCubit.scope;
    if (!mounted ||
        scope == null ||
        notice.recipientProfileId != scope.userId ||
        notice.workspaceId != scope.workspaceId) {
      return;
    }
    try {
      // Trust only the authenticated API record, never a route from FCM data.
      final record = await _pushDevices!.getNotification(notice.notificationId);
      if (!mounted ||
          _notificationsCubit.scope != scope ||
          record.id != notice.notificationId ||
          record.workspaceId != scope.workspaceId) {
        return;
      }
      if (record.isUnread) {
        final result = await _notificationsCubit.markRead(record.id);
        if (result != NotificationMutationResult.success) return;
      }
      final context =
          _router.routerDelegate.navigatorKey.currentState?.overlay?.context;
      if (!mounted ||
          context == null ||
          !context.mounted ||
          _notificationsCubit.scope != scope) {
        return;
      }
      if (record.type == NotificationType.unknown) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        return;
      }
      await NotificationsScreenNotificationNavigator.open(
        context,
        scope,
        record,
      );
    } catch (_) {
      if (!mounted || _notificationsCubit.scope != scope) return;
      final context =
          _router.routerDelegate.navigatorKey.currentState?.overlay?.context;
      if (context != null && context.mounted) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'This notification destination is no longer available.',
              ),
            ),
          ),
        );
      }
    }
  }

  T? _registered<T extends Object>() {
    final locator = widget.locator;
    if (locator == null) return null;
    if (!locator.isRegistered<T>()) {
      throw StateError('Missing production dependency: $T');
    }
    return locator<T>();
  }
}
