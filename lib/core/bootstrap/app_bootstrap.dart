import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/config/app_config.dart';
import 'package:shiftly/core/network/api_client.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/data/authentication_api_repository.dart';
import 'package:shiftly/features/auth/data/supabase_authentication_service.dart';
import 'package:shiftly/features/attendance/data/api_attendance_repository.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/attendance/data/api_leave_request_repository.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/chat/data/api_chat_repository.dart';
import 'package:shiftly/features/chat/data/chat_realtime.dart';
import 'package:shiftly/features/chat/data/chat_repository.dart';
import 'package:shiftly/features/employees/data/api_workforce_repository.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/dashboard/data/api_dashboard_repository.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/invitations/data/invitation_repository.dart';
import 'package:shiftly/features/notifications/data/api_notification_repository.dart';
import 'package:shiftly/features/notifications/data/notification_repository.dart';
import 'package:shiftly/features/profile/data/api_profile_repository.dart';
import 'package:shiftly/features/profile/data/profile_repository.dart';
import 'package:shiftly/features/shifts/data/api_shift_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';
import 'package:shiftly/features/workspaces/data/workspace_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
}

abstract final class AppBootstrap {
  static Future<AppDependencies> initialize() async {
    final config = AppConfig.fromEnvironment();
    await Supabase.initialize(
      url: config.supabaseUrl.toString(),
      publishableKey: config.supabasePublishableKey,
    );
    final preferences = await SharedPreferences.getInstance();
    final workspaceStorage = SharedPreferencesActiveWorkspaceStorage(
      preferences,
    );
    final authentication = SupabaseAuthenticationService(
      Supabase.instance.client.auth,
    );
    final apiClient = ApiClient(
      config: config,
      authentication: authentication,
      workspaceStorage: workspaceStorage,
    );
    final coordinator = SessionCoordinator(
      authentication,
      AuthenticationApiRepository(apiClient.dio),
      workspaceStorage,
    );
    final profileRepository = ApiProfileRepository(
      apiClient.dio,
      () => coordinator.state.activeMembership,
      currentUser: () => coordinator.state.currentUser,
    );
    final workforceRepository = ApiWorkforceRepository(apiClient.dio);
    final shiftRepository = ApiShiftRepository(apiClient.dio);
    final attendanceRepository = ApiAttendanceRepository(apiClient.dio);
    final leaveRequestRepository = ApiLeaveRequestRepository(apiClient.dio);
    final notificationRepository = ApiNotificationRepository(apiClient.dio);
    final dashboardRepository = ApiDashboardRepository(apiClient.dio);
    final chatRepository = ApiChatRepository(
      apiClient.dio,
      supabaseUrl: config.supabaseUrl,
    );
    return AppDependencies(
      sessionCoordinator: coordinator,
      profileRepository: profileRepository,
      employeeRepository: workforceRepository,
      invitationRepository: workforceRepository,
      workspaceRepository: workforceRepository,
      shiftRepository: shiftRepository,
      attendanceRepository: attendanceRepository,
      leaveRequestRepository: leaveRequestRepository,
      notificationRepository: notificationRepository,
      dashboardRepository: dashboardRepository,
      chatRepository: chatRepository,
      chatRealtime: SupabaseChatRealtime(Supabase.instance.client),
    );
  }
}
