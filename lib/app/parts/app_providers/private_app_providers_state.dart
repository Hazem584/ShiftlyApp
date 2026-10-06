part of '../../app_providers.dart';

class _AppProvidersState extends State<AppProviders> {
  late final EmployeeRepository _employees;
  late final InvitationRepository _invitations;
  late final WorkspaceRepository _workspaces;
  late final GoRouter _router;
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
  late final EmployeeAttendanceCubit _employeeAttendanceCubit;
  late final NotificationRepository _notifications;
  late final NotificationsCubit _notificationsCubit;
  late final ChatRepository _chat;
  late final ChatRealtime _chatRealtime;
  late final ChatGroupsCubit _chatGroupsCubit;
  late final FixedShiftRepository _fixedShifts;
  late final ManagerTemplatesCubit _managerTemplatesCubit;
  late final FlexibleAttendanceCubit _flexibleAttendanceCubit;
  late final SessionCoordinator? _sessionCoordinator;
  StreamSubscription<Object?>? _sessionSubscription;
  _SessionRouterRefresh? _sessionRefresh;
  late final SessionFeatureCoordinator _featureCoordinator;

  @override
  void initState() {
    super.initState();
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
    _sessionRefresh = _sessionCoordinator == null
        ? null
        : _SessionRouterRefresh(_sessionCoordinator);
    _router =
        widget.router ??
        createAppRouter(
          sessionCoordinator: _sessionCoordinator,
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
    _chat =
        widget.chatRepository ??
        _registered<ChatRepository>() ??
        const MockChatRepository();
    _chatRealtime =
        widget.chatRealtime ??
        _registered<ChatRealtime>() ??
        const NoopChatRealtime();
    _chatGroupsCubit = _registered<ChatGroupsCubit>() ?? ChatGroupsCubit(_chat);
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
      _leaveRequestsCubit.bindSession(previewScope);
      _notificationsCubit.bindSession(previewScope);
      _dashboardCubit.bindSession(previewScope);
      _chatGroupsCubit.bindSession(previewScope);
      _managerTemplatesCubit.bindSession(previewScope);
    } else {
      _sessionSubscription = coordinator.stream.listen(
        _featureCoordinator.bind,
      );
      _featureCoordinator.bind(coordinator.state);
    }
  }

  @override
  void dispose() {
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
    _employeeAttendanceCubit.close();
    _notificationsCubit.close();
    _chatGroupsCubit.close();
    _managerTemplatesCubit.close();
    _flexibleAttendanceCubit.close();
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
        RepositoryProvider.value(value: _notifications),
        RepositoryProvider<ChatRepository>.value(value: _chat),
        RepositoryProvider<ChatRealtime>.value(value: _chatRealtime),
        RepositoryProvider<FixedShiftRepository>.value(value: _fixedShifts),
      ],
      child: MultiBlocProvider(
        providers: [
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
          BlocProvider.value(value: _employeeAttendanceCubit),
          BlocProvider.value(value: _notificationsCubit),
          BlocProvider.value(value: _chatGroupsCubit),
          BlocProvider.value(value: _managerTemplatesCubit),
          BlocProvider.value(value: _flexibleAttendanceCubit),
        ],
        child: MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          routerConfig: _router,
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
    _employeeAttendanceCubit.bindSession(featureScope);
    _leaveRequestsCubit.bindSession(featureScope);
    _employeeLeaveRequestsCubit.bindSession(featureScope);
    _notificationsCubit.bindSession(featureScope);
    _dashboardCubit.bindSession(featureScope);
    _chatGroupsCubit.bindSession(featureScope);
    _managerTemplatesCubit.bindSession(featureScope);
    _flexibleAttendanceCubit.bindSession(featureScope);
  }

  void _invalidateDashboardAndCalendar() {
    _dashboardCubit.invalidate();
    _attendanceCalendarCubit.invalidate();
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
