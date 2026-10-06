part of '../../app_bootstrap.dart';

class AppDependencies {
  const AppDependencies({
    required this.sessionCoordinator,
    required this.profileRepository,
    required this.employeeRepository,
    required this.invitationRepository,
    required this.workspaceRepository,
    required this.shiftRepository,
    required this.attendanceRepository,
    required this.leaveRequestRepository,
    required this.notificationRepository,
    required this.dashboardRepository,
    required this.chatRepository,
    required this.chatRealtime,
    required this.fixedShiftRepository,
  });

  final SessionCoordinator sessionCoordinator;
  final ProfileRepository profileRepository;
  final EmployeeRepository employeeRepository;
  final InvitationRepository invitationRepository;
  final WorkspaceRepository workspaceRepository;
  final ShiftRepository shiftRepository;
  final AttendanceRepository attendanceRepository;
  final LeaveRequestRepository leaveRequestRepository;
  final NotificationRepository notificationRepository;
  final DashboardRepository dashboardRepository;
  final ChatRepository chatRepository;
  final ChatRealtime chatRealtime;
  final FixedShiftRepository fixedShiftRepository;
}
