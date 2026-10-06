part of '../../app_bootstrap.dart';

abstract final class AppBootstrap {
  static Future<AppDependencies> initialize() async {
    await DependencyRegistration.configureProduction();
    return AppDependencies(
      sessionCoordinator: getIt(),
      profileRepository: getIt(),
      employeeRepository: getIt(),
      invitationRepository: getIt(),
      workspaceRepository: getIt(),
      shiftRepository: getIt(),
      attendanceRepository: getIt(),
      leaveRequestRepository: getIt(),
      notificationRepository: getIt(),
      dashboardRepository: getIt(),
      chatRepository: getIt(),
      chatRealtime: getIt(),
      fixedShiftRepository: getIt(),
    );
  }
}
