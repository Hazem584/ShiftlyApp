import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/app/app_lifecycle_listener.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_cubit.dart';
import 'package:shiftly/core/localization/language_preference_store.dart';
import 'package:shiftly/core/localization/language_settings.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:shiftly/features/notifications/presentation/utils/notifications_formatters.dart';
import 'package:shiftly/features/onboarding/domain/repositories/onboarding_storage.dart';
import 'package:shiftly/features/points/domain/repositories/points_repository.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_repository.dart';
import 'package:shiftly/features/reports/data/attendance_report_exporter.dart';
import 'package:shiftly/features/reports/data/native_report_file_delivery.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

import 'app_composition.dart';
import 'app_dependencies.dart';

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

  AppDependencies get dependencies => AppDependencies(
    locator: locator,
    onboardingStorage: onboardingStorage,
    preview: preview,
    employeeRepository: employeeRepository,
    invitationRepository: invitationRepository,
    workspaceRepository: workspaceRepository,
    dashboardRepository: dashboardRepository,
    leaveRequestRepository: leaveRequestRepository,
    profileRepository: profileRepository,
    profileImagePicker: profileImagePicker,
    router: router,
    sessionCoordinator: sessionCoordinator,
    shiftRepository: shiftRepository,
    attendanceRepository: attendanceRepository,
    notificationRepository: notificationRepository,
    chatRepository: chatRepository,
    chatRealtime: chatRealtime,
    fixedShiftRepository: fixedShiftRepository,
    pointsRepository: pointsRepository,
    languageStore: languageStore,
  );

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

class _AppProvidersState extends State<AppProviders> {
  late final AppComposition _composition;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  @override
  void initState() {
    super.initState();
    _composition = AppComposition(
      widget.dependencies,
      isMounted: () => mounted,
      onOpened: _openPushNotice,
      onForeground: _showPushNotice,
    );
  }

  @override
  void dispose() {
    _composition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _composition.employees),
        RepositoryProvider.value(value: _composition.invitations),
        RepositoryProvider.value(value: _composition.workspaces),
        RepositoryProvider.value(value: _composition.leaveRequests),
        RepositoryProvider.value(value: _composition.profile),
        RepositoryProvider.value(value: _composition.profileImagePicker),
        RepositoryProvider.value(value: _composition.shifts),
        RepositoryProvider.value(value: _composition.attendance),
        RepositoryProvider<ReportExporter>(
          create: (_) => AttendanceReportExporter(),
        ),
        RepositoryProvider<ReportFileDelivery>(
          create: (_) => NativeReportFileDelivery(),
        ),
        RepositoryProvider.value(value: _composition.notifications),
        RepositoryProvider<ChatRepository>.value(value: _composition.chat),
        RepositoryProvider<ChatRealtime>.value(
          value: _composition.chatRealtime,
        ),
        RepositoryProvider<FixedShiftRepository>.value(
          value: _composition.fixedShifts,
        ),
        RepositoryProvider<PointsRepository>.value(value: _composition.points),
      ],
      child: MultiBlocProvider(
        providers: [
          if (_composition.pushNotifications != null)
            BlocProvider.value(value: _composition.pushNotifications!),
          BlocProvider.value(value: _composition.languageCubit),
          BlocProvider.value(value: _composition.onboardingCubit),
          BlocProvider.value(value: _composition.dashboardCubit),
          BlocProvider.value(value: _composition.employeesCubit),
          BlocProvider.value(value: _composition.workspacesCubit),
          BlocProvider.value(value: _composition.leaveRequestsCubit),
          BlocProvider.value(value: _composition.employeeLeaveRequestsCubit),
          BlocProvider.value(value: _composition.profileCubit),
          BlocProvider.value(value: _composition.managerShiftsCubit),
          BlocProvider.value(value: _composition.employeeShiftsCubit),
          BlocProvider.value(value: _composition.managerAttendanceCubit),
          BlocProvider.value(value: _composition.attendanceCalendarCubit),
          BlocProvider.value(value: _composition.attendanceReportsCubit),
          BlocProvider.value(value: _composition.employeeAttendanceCubit),
          BlocProvider.value(value: _composition.notificationsCubit),
          BlocProvider.value(value: _composition.chatGroupsCubit),
          BlocProvider.value(value: _composition.managerTemplatesCubit),
          BlocProvider.value(value: _composition.flexibleAttendanceCubit),
          BlocProvider.value(value: _composition.pointsCubit),
          BlocProvider.value(value: _composition.managerPerformanceCubit),
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
            routerConfig: _composition.router,
          ),
        ),
      ),
    );
    final coordinator = _composition.sessionCoordinator;
    final provided = coordinator == null
        ? app
        : BlocProvider<SessionCoordinator>.value(
            value: coordinator,
            child: app,
          );
    return ShiftlyAppLifecycleListener(
      onResumed: () {
        unawaited(_composition.pushNotifications?.refresh());
        unawaited(_composition.flexibleAttendanceCubit.load(refresh: true));
        unawaited(_composition.notificationsCubit.refreshUnreadCount());
        unawaited(_composition.chatGroupsCubit.refreshUnread());
        _composition.dashboardCubit.invalidate();
      },
      child: provided,
    );
  }

  Future<void> _showPushNotice(PushNotice notice) async {
    unawaited(_composition.notificationsCubit.load(refresh: true));
    _composition.dashboardCubit.invalidate();
    final scope = _composition.notificationsCubit.scope;
    if (scope == null || _composition.pushDevices == null) return;
    String? content;
    try {
      final record = await _composition.pushDevices!.getNotification(
        notice.notificationId,
      );
      if (!mounted ||
          _composition.notificationsCubit.scope != scope ||
          record.workspaceId != scope.workspaceId ||
          record.id != notice.notificationId) {
        return;
      }
      content = '${record.title}\n${record.message}';
    } catch (_) {
      return;
    }
    final context = _composition
        .router
        .routerDelegate
        .navigatorKey
        .currentState
        ?.overlay
        ?.context;
    if (!mounted || context == null || !context.mounted) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(content),
        action: SnackBarAction(
          label: context.tr('View'),
          onPressed: () => unawaited(_openPushNotice(notice)),
        ),
      ),
    );
  }

  Future<void> _openPushNotice(PushNotice notice) async {
    final scope = _composition.notificationsCubit.scope;
    if (!mounted ||
        scope == null ||
        notice.recipientProfileId != scope.userId ||
        notice.workspaceId != scope.workspaceId) {
      return;
    }
    try {
      // Trust only the authenticated API record, never a route from FCM data.
      final record = await _composition.pushDevices!.getNotification(
        notice.notificationId,
      );
      if (!mounted ||
          _composition.notificationsCubit.scope != scope ||
          record.id != notice.notificationId ||
          record.workspaceId != scope.workspaceId) {
        return;
      }
      if (record.isUnread) {
        final result = await _composition.notificationsCubit.markRead(
          record.id,
        );
        if (result != NotificationMutationResult.success) return;
      }
      final context = _composition
          .router
          .routerDelegate
          .navigatorKey
          .currentState
          ?.overlay
          ?.context;
      if (!mounted ||
          context == null ||
          !context.mounted ||
          _composition.notificationsCubit.scope != scope) {
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
      if (!mounted || _composition.notificationsCubit.scope != scope) return;
      final context = _composition
          .router
          .routerDelegate
          .navigatorKey
          .currentState
          ?.overlay
          ?.context;
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
}
