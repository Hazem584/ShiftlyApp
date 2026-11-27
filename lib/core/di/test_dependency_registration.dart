import 'package:get_it/get_it.dart';
import 'package:shiftly/core/di/test_cubit_registration.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/data/api_attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/onboarding/data/memory_onboarding_storage.dart';
import 'package:shiftly/features/onboarding/domain/repositories/onboarding_storage.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

void registerTestDependencies({
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
}) {
  if (locator.isRegistered<SessionCoordinator>()) {
    throw StateError(
      'Reset test dependencies before registering replacements.',
    );
  }
  locator
    ..registerSingleton<OnboardingStorage>(
      onboardingStorage ?? MemoryOnboardingStorage(),
    )
    ..registerSingleton<SessionCoordinator>(
      sessionCoordinator,
      dispose: (c) => c.close(),
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
        locator(),
        locator(),
        locator(),
        dio: null,
      ),
    )
    ..registerSingleton<NotificationRepository>(notificationRepository)
    ..registerSingleton<DashboardRepository>(dashboardRepository)
    ..registerSingleton<ChatRepository>(chatRepository)
    ..registerSingleton<ChatRealtime>(chatRealtime)
    ..registerSingleton<FixedShiftRepository>(fixedShiftRepository)
    ..registerSingleton<ProfileImagePicker>(
      profileImagePicker ?? DeviceProfileImagePicker(),
    );
  registerTestCubits(locator);
}
