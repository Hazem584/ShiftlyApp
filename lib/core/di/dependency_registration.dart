import 'package:dio/dio.dart';
import 'package:shiftly/features/manager_performance/data/api_manager_points_repository.dart';
import 'package:shiftly/features/manager_performance/data/manager_points_repository.dart';
import 'package:shiftly/features/manager_performance/data/manager_intent_storage.dart';
import 'package:shiftly/features/manager_performance/data/preferences_manager_intent_storage.dart';
import 'package:shiftly/features/manager_performance/data/memory_manager_intent_storage.dart';
import 'package:shiftly/features/manager_performance/data/unavailable_manager_points_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/config/app_config.dart';
import 'package:shiftly/core/di/dependency_disposal.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/network/api_client.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/attendance/data/api_attendance_repository.dart';
import 'package:shiftly/features/attendance/data/api_leave_request_repository.dart';
import 'package:shiftly/features/attendance/data/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/auth/data/authentication_api_repository.dart';
import 'package:shiftly/features/auth/data/supabase_authentication_service.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:shiftly/features/chat/data/api_chat_repository.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/chat/data/signed_chat_upload_client.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/dashboard/data/api_dashboard_repository.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/employees/data/api_workforce_repository.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employee_details_cubit.dart';
import 'package:shiftly/features/fixed_shifts/data/api_fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/invitations/data/invitation_repository.dart';
import 'package:shiftly/features/notifications/data/api_notification_repository.dart';
import 'package:shiftly/features/notifications/data/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/profile/data/api_profile_repository.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';
import 'package:shiftly/features/points/data/api_points_repository.dart';
import 'package:shiftly/features/points/data/mock_points_repository.dart';
import 'package:shiftly/features/points/data/points_repository.dart';
import 'package:shiftly/features/points/data/redemption_intent_storage.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';
import 'package:shiftly/features/shifts/data/api_shift_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';
import 'package:shiftly/features/workspaces/data/workspace_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class DependencyRegistration {
  static Future<void> configureProduction({GetIt? locator}) async {
    final target = locator ?? getIt;
    await DependencyDisposal.reset(locator: target);
    final config = AppConfig.fromEnvironment();
    await Supabase.initialize(
      url: config.supabaseUrl.toString(),
      publishableKey: config.supabasePublishableKey,
    );
    final preferences = await SharedPreferences.getInstance();
    target
      ..registerSingleton<AppConfig>(config)
      ..registerSingleton<SupabaseClient>(Supabase.instance.client)
      ..registerSingleton<SharedPreferences>(preferences)
      ..registerLazySingleton<ActiveWorkspaceStorage>(
        () => SharedPreferencesActiveWorkspaceStorage(target()),
      )
      ..registerLazySingleton<AuthenticationService>(
        () => SupabaseAuthenticationService(target<SupabaseClient>().auth),
      )
      ..registerLazySingleton<ApiClient>(
        () => ApiClient(
          config: target(),
          authentication: target(),
          workspaceStorage: target(),
        ),
        dispose: (client) => client.dio.close(force: true),
      )
      ..registerLazySingleton<Dio>(() => target<ApiClient>().dio)
      ..registerLazySingleton<AuthenticationRepository>(
        () => AuthenticationApiRepository(target()),
      )
      ..registerLazySingleton<SessionCoordinator>(
        () => SessionCoordinator(target(), target(), target()),
        dispose: (coordinator) => coordinator.close(),
      )
      ..registerLazySingleton<ApiWorkforceRepository>(
        () => ApiWorkforceRepository(target()),
      )
      ..registerLazySingleton<EmployeeRepository>(
        () => target<ApiWorkforceRepository>(),
      )
      ..registerLazySingleton<InvitationRepository>(
        () => target<ApiWorkforceRepository>(),
      )
      ..registerLazySingleton<WorkspaceRepository>(
        () => target<ApiWorkforceRepository>(),
      )
      ..registerLazySingleton<ShiftRepository>(
        () => ApiShiftRepository(target()),
      )
      ..registerLazySingleton<AttendanceRepository>(
        () => ApiAttendanceRepository(target()),
      )
      ..registerLazySingleton<LeaveRequestRepository>(
        () => ApiLeaveRequestRepository(target()),
      )
      ..registerLazySingleton<AttendanceCalendarRepository>(
        () => ApiAttendanceCalendarRepository(target(), target(), target()),
      )
      ..registerLazySingleton<NotificationRepository>(
        () => ApiNotificationRepository(target()),
      )
      ..registerLazySingleton<DashboardRepository>(
        () => ApiDashboardRepository(target()),
      )
      ..registerLazySingleton<PointsRepository>(
        () => ApiPointsRepository(target()),
      )
      ..registerLazySingleton<ManagerPointsRepository>(
        () => ApiManagerPointsRepository(target()),
      )
      ..registerLazySingleton<ManagerIntentStorage>(
        () => PreferencesManagerIntentStorage(target()),
      )
      ..registerLazySingleton<RedemptionIntentStorage>(
        () => SharedPreferencesRedemptionIntentStorage(target()),
      )
      ..registerLazySingleton<FixedShiftRepository>(
        () => ApiFixedShiftRepository(target(), target()),
      )
      ..registerLazySingleton<ProfileRepository>(
        () => ApiProfileRepository(
          target(),
          () => target<SessionCoordinator>().state.activeMembership,
          currentUser: () => target<SessionCoordinator>().state.currentUser,
        ),
      )
      ..registerLazySingleton<ProfileImagePicker>(DeviceProfileImagePicker.new)
      ..registerLazySingleton<SupabaseChatStorageUploader>(
        () => SupabaseChatStorageUploader(target()),
      )
      ..registerLazySingleton<ChatRepository>(
        () => ApiChatRepository(
          target(),
          storageUploader: target<SupabaseChatStorageUploader>(),
        ),
      )
      ..registerLazySingleton<ChatRealtime>(
        () => SupabaseChatRealtime(target()),
      )
      ..registerFactory<DashboardCubit>(() => DashboardCubit(target()))
      ..registerFactory<PointsCubit>(
        () => PointsCubit(target(), intentStorage: target()),
      )
      ..registerFactory<NotificationsCubit>(() => NotificationsCubit(target()))
      ..registerFactory<ChatGroupsCubit>(() => ChatGroupsCubit(target()))
      ..registerFactory<ManagerTemplatesCubit>(
        () => ManagerTemplatesCubit(target()),
      )
      ..registerFactory<WorkPatternCubit>(() => WorkPatternCubit(target()))
      ..registerFactory<EmployeeDetailsCubit>(
        () => EmployeeDetailsCubit(target()),
      );
  }

  static void configureTestDependencies({
    required GetIt locator,
    required SessionCoordinator sessionCoordinator,
    required ProfileRepository profileRepository,
    required EmployeeRepository employeeRepository,
    required InvitationRepository invitationRepository,
    required WorkspaceRepository workspaceRepository,
    required ShiftRepository shiftRepository,
    required AttendanceRepository attendanceRepository,
    required LeaveRequestRepository leaveRequestRepository,
    required NotificationRepository notificationRepository,
    required DashboardRepository dashboardRepository,
    required ChatRepository chatRepository,
    required ChatRealtime chatRealtime,
    required FixedShiftRepository fixedShiftRepository,
    PointsRepository? pointsRepository,
    ManagerPointsRepository? managerPointsRepository,
    ProfileImagePicker? profileImagePicker,
  }) {
    if (locator.isRegistered<SessionCoordinator>()) {
      throw StateError(
        'Reset test dependencies before registering replacements.',
      );
    }
    locator
      ..registerSingleton<SessionCoordinator>(
        sessionCoordinator,
        dispose: (coordinator) => coordinator.close(),
      )
      ..registerSingleton<ProfileRepository>(profileRepository)
      ..registerSingleton<EmployeeRepository>(employeeRepository)
      ..registerSingleton<InvitationRepository>(invitationRepository)
      ..registerSingleton<WorkspaceRepository>(workspaceRepository)
      ..registerSingleton<ShiftRepository>(shiftRepository)
      ..registerSingleton<AttendanceRepository>(attendanceRepository)
      ..registerSingleton<LeaveRequestRepository>(leaveRequestRepository)
      ..registerLazySingleton<AttendanceCalendarRepository>(
        () => ApiAttendanceCalendarRepository(
          locator<ShiftRepository>(),
          locator<AttendanceRepository>(),
          locator<LeaveRequestRepository>(),
        ),
      )
      ..registerSingleton<NotificationRepository>(notificationRepository)
      ..registerSingleton<DashboardRepository>(dashboardRepository)
      ..registerSingleton<ChatRepository>(chatRepository)
      ..registerSingleton<ChatRealtime>(chatRealtime)
      ..registerSingleton<FixedShiftRepository>(fixedShiftRepository)
      ..registerSingleton<PointsRepository>(
        pointsRepository ?? const MockPointsRepository(),
      )
      ..registerSingleton<ManagerPointsRepository>(
        managerPointsRepository ?? const UnavailableManagerPointsRepository(),
      )
      ..registerSingleton<ManagerIntentStorage>(MemoryManagerIntentStorage())
      ..registerSingleton<RedemptionIntentStorage>(
        MemoryRedemptionIntentStorage(),
      )
      ..registerSingleton<ProfileImagePicker>(
        profileImagePicker ?? DeviceProfileImagePicker(),
      )
      ..registerFactory<DashboardCubit>(
        () => DashboardCubit(locator<DashboardRepository>()),
      )
      ..registerFactory<PointsCubit>(
        () => PointsCubit(
          locator<PointsRepository>(),
          intentStorage: locator<RedemptionIntentStorage>(),
        ),
      )
      ..registerFactory<NotificationsCubit>(
        () => NotificationsCubit(locator<NotificationRepository>()),
      )
      ..registerFactory<ChatGroupsCubit>(
        () => ChatGroupsCubit(locator<ChatRepository>()),
      )
      ..registerFactory<ManagerTemplatesCubit>(
        () => ManagerTemplatesCubit(locator<FixedShiftRepository>()),
      )
      ..registerFactory<WorkPatternCubit>(
        () => WorkPatternCubit(locator<FixedShiftRepository>()),
      )
      ..registerFactory<EmployeeDetailsCubit>(
        () => EmployeeDetailsCubit(locator<EmployeeRepository>()),
      );
  }
}
