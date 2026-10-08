import 'package:shiftly/app/app_providers.dart';

class ShiftlyApp extends AppProviders {
  /// Authenticated startup supplies the fully configured production locator.
  const ShiftlyApp({
    super.key,
    super.locator,
    super.employeeRepository,
    super.invitationRepository,
    super.workspaceRepository,
    super.dashboardRepository,
    super.leaveRequestRepository,
    super.profileRepository,
    super.profileImagePicker,
    super.router,
    super.sessionCoordinator,
    super.shiftRepository,
    super.attendanceRepository,
    super.notificationRepository,
    super.chatRepository,
    super.chatRealtime,
    super.fixedShiftRepository,
    super.pointsRepository,
  });

  /// Explicit preview/test composition with constructor-provided replacements.
  const ShiftlyApp.preview({
    super.key,
    super.preview = true,
    super.employeeRepository,
    super.invitationRepository,
    super.workspaceRepository,
    super.dashboardRepository,
    super.leaveRequestRepository,
    super.profileRepository,
    super.profileImagePicker,
    super.router,
    super.sessionCoordinator,
    super.shiftRepository,
    super.attendanceRepository,
    super.notificationRepository,
    super.chatRepository,
    super.chatRealtime,
    super.fixedShiftRepository,
    super.pointsRepository,
  });
}
