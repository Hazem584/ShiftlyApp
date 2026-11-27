import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/config/app_config.dart';
import 'package:shiftly/core/di/collaboration_dependency_registration.dart';
import 'package:shiftly/core/di/core_dependency_registration.dart';
import 'package:shiftly/core/di/dependency_disposal.dart';
import 'package:shiftly/core/di/operations_dependency_registration.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/di/test_dependency_registration.dart';
import 'package:shiftly/core/di/workforce_dependency_registration.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/chat/data/cache/chat_cache_database.dart';
import 'package:shiftly/features/chat/data/cache/chat_database_factory.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/onboarding/domain/repositories/onboarding_storage.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final chatDb = await ChatCacheDatabase.open(await chatStorageDirectory());
    registerCoreProductionDependencies(target, config, prefs, chatDb);
    registerWorkforceProductionDependencies(target);
    registerCollaborationProductionDependencies(target);
    registerOperationsAndFactoryDependencies(target);
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
    OnboardingStorage? onboardingStorage,
    ProfileImagePicker? profileImagePicker,
  }) => registerTestDependencies(
    locator: locator,
    sessionCoordinator: sessionCoordinator,
    profileRepository: profileRepository,
    employeeRepository: employeeRepository,
    invitationRepository: invitationRepository,
    workspaceRepository: workspaceRepository,
    shiftRepository: shiftRepository,
    attendanceRepository: attendanceRepository,
    leaveRequestRepository: leaveRequestRepository,
    notificationRepository: notificationRepository,
    dashboardRepository: dashboardRepository,
    chatRepository: chatRepository,
    chatRealtime: chatRealtime,
    fixedShiftRepository: fixedShiftRepository,
    onboardingStorage: onboardingStorage,
    profileImagePicker: profileImagePicker,
  );
}
